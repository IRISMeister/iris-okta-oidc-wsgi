Class MyApps.Installer
{

ClassMethod setup(ByRef tVars) As %Status
{
  Set tSC='$$$OK
  Try {
    New $NAMESPACE
    Set $NAMESPACE="%SYS"

    #; enable callin. This is required only if you want to try callin.py
    kill prop
    Set tSC=##class(Security.Services).Get("%service_callin",.prop)
    $$$ThrowOnError(tSC)
    Set prop("Enabled")=1
    Set tSC=##class(Security.Services).Modify("%service_callin",.prop)
    $$$ThrowOnError(tSC)

    Set tSC=##Class(%SYS.Python.WSGI).CreateApp("app")
    Set webapp="/csp/sys/wsgi/app" Kill props
    Set tSC = ##Class(Security.Applications).Get(webapp,.props)
    Set props("AutheEnabled")=64
    Set props("MatchRoles")=":%All"
    Set tSC = ##Class(Security.Applications).Modify(webapp,.props)
    $$$ThrowOnError(tSC)

  } Catch(e) {
	  Set tSC=e.AsStatus()
    zw tSC
  }
  Return tSC
}

}
