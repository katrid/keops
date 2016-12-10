import os
import json
from xml.etree import ElementTree as et
import pyodbc
from django.shortcuts import render
from django.http import JsonResponse
from django.conf import settings
from django.utils.translation import gettext as _


def dashboard(request):
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
    if request.method == 'POST':
        pass


def get_report_file(filename):
    return et.fromstring(open(os.path.join('reports', filename), encoding='utf-8').read())

conn_str = 'Dsn=gsf;uid=sped2;pwd=sped2'
conn = pyodbc.connect(conn_str)


def choices(request):
    if 'sql_choices' in request.GET:
        xml = get_report_file(request.GET['file'])
        for el in xml.findall("./fields/field/[@name='%s']" % request.GET['sql_choices']):
            sql_choices = el.attrib['sql-choices']
            cur = conn.cursor()
            cur.execute(sql_choices)
            return JsonResponse({'items': [{'id': row[0], 'text': row[1]} for row in cur.fetchmany(50)], 'count': 50})
