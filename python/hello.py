import os
import sys
sys.path += ['/usr/irissys/lib/python','/usr/irissys/mgr/python']
from flask import Flask,render_template,request

app = Flask(__name__)

@app.route("/")
def hello_world():
    path=os.environ['PATH'] 
    return "<p>Hello, from InterSystems IRIS Embedded Python!</p>"

@app.route("/cgienv")
def env():
    agent=request.environ.get('HTTP_USER_AGENT')
    return "<p>Hello,"+agent+", from InterSystems IRIS Embedded Python!</p>"

@app.route("/ns")
def ns():
    import iris
    ns=iris.cls('%SYSTEM.Process').NameSpace()
    return render_template("index.html",namespace=ns)

@app.route("/procs")
def getprocs():
    rs = iris.sql.exec("SELECT NameSpace, Routine, LinesExecuted, GlobalReferences, State, PidExternal FROM %SYS.ProcessQuery")
    return render_template("procs.html",rows=[row for idx,row in enumerate(rs)])
