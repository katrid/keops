import re
import os
import json
from xml.etree import ElementTree as et
import tempfile
from django.shortcuts import render
from django.http import JsonResponse
from django.conf import settings
from django.utils.translation import gettext as _
from django.contrib.auth.decorators import login_required

from keops.models import reports as report_models
from keops.contrib.base.models import Menu


@login_required
def dashboard(request):
    if request.method == 'POST':
        return report(request)
    reps = os.listdir(os.path.join(settings.BASE_DIR, 'reports'))
    reports = []
    fields = []
    rep = None
    for f in reps:
        if f.endswith('.xml'):
            xml = et.fromstring(open(os.path.join(settings.BASE_DIR, 'reports', f), encoding='utf-8').read())
            reports.append({'filename': f, 'name': xml.attrib.get('name', f)})

    user_params = None
    user_report = None
    if 'file' in request.GET:
        rep = {}
        filename = request.GET['file']
        xml = get_report_file(filename)
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
        user_report = request.GET.get('load')
        if user_report:
            user_report = report_models.UserReport.objects.get(pk=request.GET['load'])
            user_params = json.loads(user_report.user_params)

    groups = None
    if request.user.is_superuser:
        menu = Menu.objects.filter(parent_id=None)
    else:
        groups = [obj.pk for obj in request.user.groups.all()]
        menu = Menu.objects.filter(parent_id=None, groups__in=groups)

    return render(request, 'keops/reports/dashboard.html', {
        '_': _,
        'user_reports': report_models.UserReport.objects.filter(report__name=request.GET.get('file')),
        'current_menu': None,
        'settings': settings,
        'reports': reports,
        'fields': fields,
        'report': rep,
        'menu': menu,
        'user_report': user_report,
        'user_params': user_params,
    })


@login_required
def report(request):

    def clone(file, params, dest_file, templ):
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
                elif param['operation'] == 'startsWith':
                    sqls.append("upper({0}) like upper('{1}%')".format(param['name'], param['value1']))
                elif param['operation'] == 'equals':
                    sqls.append("{0} = '{1}'".format(param['name'], param['value1']))
                elif param['operation'] == 'between':
                    sqls.append("{0} BETWEEN {1} and {2}".format(param['name'], val1, val2))
        sql = ' AND '.join(sqls)

        sel_cmd = templ.findall('.//dataset')[0].text

        datasource = xml.findall('.//TableDataSource')[0]
        sel_cmd = sel_cmd % params['file'].rsplit('.', 1)[0]
        sorting = params.get('sorting')
        if sorting:
            sql += ' ORDER BY ' + ','.join(sorting)
        if sql:
            pattern = re.compile(r"/\*where\*/", re.IGNORECASE)
            sel_cmd = pattern.sub(sql, sel_cmd)
            pattern = re.compile(r"/\*where-clause\*/", re.IGNORECASE)
            sel_cmd = pattern.sub(' WHERE ' + sql, sel_cmd)
            pattern = re.compile(r"/\*whereclause\*/", re.IGNORECASE)
            sel_cmd = pattern.sub(' WHERE ' + sql, sel_cmd)
        print(sel_cmd)
        datasource.attrib['SelectCommand'] = sel_cmd

        et.ElementTree(xml).write(dest_file, encoding='utf-8', xml_declaration=True)

    if request.method == 'POST':
        if request.is_ajax():
            params = json.loads(request.body.decode('utf-8'))
            if 'save' in request.GET:
                rep = report_models.Report.objects.create(name=params['file'])
                user_report_name = request.GET['save']
                if report_models.UserReport.objects.filter(name=user_report_name).count():
                    user_report = report_models.UserReport.objects.get(name=user_report_name)
                else:
                    user_report = report_models.UserReport()
                user_report.report_id = rep.pk
                user_report.name = user_report_name
                user_report.user_params = request.body.decode('utf-8')
                user_report.save()
                return JsonResponse({'message': 'Success', 'ok': True, 'status': 'ok'})
            else:
                data = params['data']
                format = params.get('format', 'pdf')
                filename = params['file']
                report_template = get_report_file(filename)
                report_file = report_template.attrib['report-file']
                report_file = os.path.join(settings.BASE_DIR, 'reports', report_file)
                outname = next(tempfile._get_candidate_names())
                destfile = outname + '.' + format
                destfrx = os.path.join(settings.REPORT_ROOT, outname + '.frx')
                clone(report_file, params, destfrx, report_template)
                outname = os.path.join(settings.REPORT_ROOT, destfile)
                download = '/reports/temp/%s' % destfile
                ret = {'open': download}
                import fastreport
                fastreport.show_report(destfrx, outname, format, 'Dsn=gsf;uid=sped2;pwd=sped2', '', '', {})
                #os.unlink(destfrx)
                return JsonResponse(ret)


def get_report_file(filename):
    return et.fromstring(open(os.path.join(settings.BASE_DIR, 'reports', filename), encoding='utf-8').read())


@login_required
def choices(request):
    if 'sql_choices' in request.GET:
        import pyodbc
        conn_str = 'Dsn=gsf;uid=sped2;pwd=sped2'
        conn = pyodbc.connect(conn_str)
        xml = get_report_file(request.GET['file'])
        for el in xml.findall("./fields/field/[@name='%s']" % request.GET['sql_choices']):
            sql_choices = el.attrib['sql-choices']
            cur = conn.cursor()
            cur.execute(sql_choices)
            return JsonResponse({'items': [{'id': row[0], 'text': row[1]} for row in cur.fetchmany(50)], 'count': 50})
