import os
import json
from xml.etree import ElementTree as et
import pyodbc
import tempfile
from django.shortcuts import render
from django.http import JsonResponse
from django.conf import settings
from django.utils.translation import gettext as _
import fastreport


def dashboard(request):
    if request.method == 'POST':
        return report(request)
    reps = os.listdir('./reports')
    reports = []
    fields = []
    rep = None
    for f in reps:
        if f.endswith('.xml'):
            xml = et.fromstring(open(os.path.join('reports', f)).read())
            reports.append({'filename': f, 'name': xml.attrib.get('name', f)})

    if 'file' in request.GET:
        rep = {}
        filename = request.GET['file']
        xml = et.fromstring(open(os.path.join('reports', filename), encoding='utf-8').read())
        rep.update(xml.attrib)
        for el in xml:
            if el.tag == 'fields':
                rep['fields'] = fields
                for field in el:
                    attrs = {k.replace('-', '_'): v for k, v in dict(field.attrib).items()}
                    param = attrs.get('param')
                    if param == 'true':
                        attrs['param'] = True
                    if 'sql_choices' in attrs:
                        attrs['sql_choices'] = True
                    fields.append(attrs)
        rep['file'] = request.GET['file']
        rep = json.dumps(rep)

    return render(request, 'keops/reports/dashboard.html', {
        '_': _,
        'current_menu': None,
        'settings': settings,
        'reports': reports,
        'fields': fields,
        'report': rep,
    })


def report(request):

    def clone(file, params, dest_file):
        group_template = '''
    <GroupHeaderBand Name="GroupHeader_{0}" Top="102.5" Width="1047.06" Height="37.8" Condition="[Master.{0}]">
    {1}
    </GroupHeaderBand>
        '''
        group_footer = '''<GroupFooterBand Name="GroupFooter_{0}" Top="167.2" Width="1047.06" Height="37.8"/>'''
        group_field = '''<TextObject Name="Text_g_{0}" Top="9.45" Width="270" Height="18.9" Text="[Master.{0}]"/>'''

        xml = et.fromstring(open(file, 'r', encoding='utf-8').read())
        fields = {}
        pos_fields = {}
        report_page = xml.findall('./ReportPage')[0]
        dictionary = xml.findall('./Dictionary')[0]
        summary = xml.findall('./ReportPage/ReportSummaryBand')[0]
        data_band = xml.findall('./ReportPage/DataBand')[0]
        for el in report_template.findall("./fields/field"):
            fields[el.attrib['name']] = el.attrib
        if params.get('fields'):
            cx = 0
            field_templ = '''<TextObject Name="Text_{0}" Width="{2}" CanGrow="true" Height="18.9" Left="{1}" VertAlign="Center" Text="[Master.{0}]" Font="Arial, 8pt" {3}/>'''
            header_templ = '''<TextObject Name="Text_h_{0}" Width="{3}" Height="18.9" Text="{1}" Left="{2}" VertAlign="Center" Font="Arial, 8pt, style=Bold" {4}/>'''
            page_header = xml.findall('./ReportPage/PageHeaderBand')[0]
            for txt in list(data_band):
                data_band.remove(txt)
            for txt in list(page_header):
                page_header.remove(txt)
            for field in params['fields']:
                w = 80
                ftype = fields[field].get('type', 'str')
                fmt_field = ''
                fmt_header = ''
                if ftype == 'str':
                    w = 160
                elif ftype == 'decimal':
                    w = 100
                    fmt_field = '''Format="Currency" Format.UseLocale="true" HorzAlign="Right" WordWrap="false"'''
                    fmt_header = '''HorzAlign="Right"'''
                data_band.append(et.fromstring(field_templ.format(field, cx, w, fmt_field)))
                page_header.append(et.fromstring(header_templ.format(field, fields[field].get('label', field), cx, w, fmt_header)))
                pos_fields[field] = (cx, w)
                cx += w
        if params.get('grouping'):
            field_templ = '''<TextObject Name="Text_t_{3}_{0}" Width="{2}" CanGrow="true" Height="18.9" Left="{1}" Text="[Total_{3}_{0}]" Font="Arial, 8pt, style=Bold" Format="Currency" Format.UseLocale="true" HorzAlign="Right" WordWrap="false"/>'''
            total_templ = '''<Total Name="Total_{1}_{0}" Expression="[Master.{0}]" Evaluator="Data1" PrintOn="GroupFooter_{1}"/>'''
            for group in params['grouping']:
                g_text = group_field.format(group)
                g = et.fromstring(group_template.format(group, g_text))
                report_page.append(g)
                report_page.remove(data_band)
                g.append(data_band)
                gf = et.fromstring(group_footer.format(group,))
                g.append(gf)
                if params.get('totals'):
                    for total in params['totals']:
                        dictionary.append(et.fromstring(total_templ.format(total, group)))
                        footer_text = et.fromstring(field_templ.format(total, pos_fields[total][1], pos_fields[total][0], group))
                        gf.append(footer_text)

        if params.get('totals'):
            field_templ = '''<TextObject Name="Text_t_{0}" Width="{2}" CanGrow="true" Height="18.9" Left="{1}" Text="[Total_{0}]" Font="Arial, 8pt, style=Bold" Format="Currency" Format.UseLocale="true" HorzAlign="Right" WordWrap="false"/>'''
            total_templ = '''<Total Name="Total_{0}" Expression="[Master.{0}]" Evaluator="Data1"/>'''
            for total in params['totals']:
                dictionary.append(et.fromstring(total_templ.format(total)))
                footer_text = et.fromstring(field_templ.format(total, pos_fields[total][1], pos_fields[total][0]))
                summary.append(footer_text)

        # Get sql
        sqls = ['1 = 1']
        for param in params['data']:
            if 'value1' in param and param['value1']:
                val1 = param['value1']
                val2 = param.get('value2')
                if param['type'] == 'datetime':
                    if val1:
                        val1 = "TO_DATE('%s', 'dd/mm/yyyy')" % val1
                    if val2:
                        val2 = "TO_DATE('%s', 'dd/mm/yyyy')" % val2
                if param['operation'] == 'contains':
                    sqls.append("upper({0}) like upper('%{1}%')".format(param['name'], param['value1']))
                elif param['operation'] == 'equals':
                    sqls.append("{0} = '{1}'".format(param['name'], param['value1']))
                elif param['operation'] == 'between':
                    sqls.append("{0} BETWEEN {1} and {2}".format(param['name'], val1, val2))
        sql = ' AND '.join(sqls)

        datasource = xml.findall('.//TableDataSource')[0]
        sel_cmd = datasource.attrib['SelectCommand']
        sorting = params.get('sorting')
        if sorting:
            sql += ' ORDER BY ' + ','.join(sorting)
        if sql:
            sel_cmd = sel_cmd.replace('/*where*/', sql)
            sel_cmd = sel_cmd.replace('/*where-clause*/', ' WHERE ' + sql)
        datasource.attrib['SelectCommand'] = sel_cmd

        et.ElementTree(xml).write(dest_file, encoding='utf-8', xml_declaration=True)

    if request.method == 'POST':
        if request.is_ajax():
            params = json.loads(request.body.decode('utf-8'))
            data = params['data']
            format = params.get('format', 'pdf')
            filename = params['file']
            report_template = get_report_file(filename)
            report_file = report_template.attrib['report-file']
            report_file = os.path.join('reports', report_file)
            outname = next(tempfile._get_candidate_names())
            destfile = outname + '.' + format
            destfrx = os.path.join(settings.REPORT_ROOT, outname + '.frx')
            clone(report_file, params, destfrx)
            outname = os.path.join(settings.REPORT_ROOT, destfile)
            download = '/reports/temp/%s' % destfile
            ret = {'open': download}
            fastreport.show_report(destfrx, outname, format, 'Dsn=gsf;uid=sped2;pwd=sped2', '', '', {})
            #os.unlink(destfrx)
            return JsonResponse(ret)


def get_report_file(filename):
    return et.fromstring(open(os.path.join('reports', filename), encoding='utf-8').read())


def choices(request):
    if 'sql_choices' in request.GET:
        conn_str = 'Dsn=gsf;uid=sped2;pwd=sped2'
        conn = pyodbc.connect(conn_str)
        xml = get_report_file(request.GET['file'])
        for el in xml.findall("./fields/field/[@name='%s']" % request.GET['sql_choices']):
            sql_choices = el.attrib['sql-choices']
            cur = conn.cursor()
            cur.execute(sql_choices)
            return JsonResponse({'items': [{'id': row[0], 'text': row[1]} for row in cur.fetchmany(50)], 'count': 50})
