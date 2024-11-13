# Linux 非コンテナ環境で動作させる場合の注意点

事前にIRISのインストールとapacheのCSP構成が必要です。

```
(*) IRISをowner=rootでインストールするとpython使用時に、import irisでエラーになります。
Traceback (most recent call last):
  File "/home/irismeister/git/iris-wsgi/python/hello.py", line 3, in <module>
    import iris
  File "/usr/irissys/lib/python/iris.py", line 14, in <module>
    from pythonint import *
ImportError: IrisSecureStart failed: IRIS_ATTACH (-21)

下記コマンドでユーザをirisusrグループに加えてください。
$ sudo usermod -aG irisusr $USER
```

