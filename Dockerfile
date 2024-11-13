FROM containers.intersystems.com/intersystems/iris-community:2024.1

USER root
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y curl vim
### IRIS itself doesn't require ja language pack
RUN apt-get update && apt-get install -y tzdata language-pack-ja && update-locale LANG=ja_JP.UTF-8


USER irisowner
COPY --chown=$ISC_PACKAGE_IRISUSER:$ISC_PACKAGE_IRISGROUP src src


# 先にflaskをインストールしないと##Class(%SYS.Python.WSGI).CreateApp()がエラーになる。
COPY --chown=$ISC_PACKAGE_IRISUSER:$ISC_PACKAGE_IRISGROUP python/requirements.txt .
RUN pip3 install -r $HOME/requirements.txt --target /usr/irissys/mgr/python

RUN  iris start $ISC_PACKAGE_INSTANCENAME \
 && printf 'Do ##class(Config.NLS.Locales).Install("jpuw") h\n' | iris session $ISC_PACKAGE_INSTANCENAME -U %SYS \
 && printf 'Set tSC=$system.OBJ.Load("'$HOME/src'/MyApps/Installer.cls","ck") Do:+tSC=0 $SYSTEM.Process.Terminate($JOB,1) h\n' | iris session $ISC_PACKAGE_INSTANCENAME \
 && printf 'Set tSC=##class(MyApps.Installer).setup() Do:+tSC=0 $SYSTEM.Process.Terminate($JOB,1) h\n' | iris session $ISC_PACKAGE_INSTANCENAME \
 && iris stop $ISC_PACKAGE_INSTANCENAME quietly

RUN iris start $ISC_PACKAGE_INSTANCENAME nostu quietly \
 && printf "kill ^%%SYS(\"JOURNAL\") kill ^SYS(\"NODE\") h\n" | iris session $ISC_PACKAGE_INSTANCENAME -B | cat \
 && iris stop $ISC_PACKAGE_INSTANCENAME quietly bypass \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/journal.log \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/IRIS.WIJ \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/iris.ids \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/alerts.log \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/journal/* \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/messages.log \
 && touch $ISC_PACKAGE_INSTALLDIR/mgr/messages.log \
 && rm -rf src \
 && echo $COMMIT_ID > $HOME/commit.txt

#  ##Class(%SYS.Python.WSGI).CreateApp()がhello.pyを上書き作成するので、この処理は最後に実行。
COPY --chown=$ISC_PACKAGE_IRISUSER:$ISC_PACKAGE_IRISGROUP python/ /usr/irissys/mgr/python
COPY --chown=$ISC_PACKAGE_IRISUSER:$ISC_PACKAGE_IRISGROUP python/.env /usr/irissys/mgr/user
