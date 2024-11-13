# iris-okta-oidc-wsgi

[以前](https://jp.community.intersystems.com/node/540316)、Azure用にOAouth2クライアントをセットアップする記事を書いた時に思ったのですが、各IdPはサンプルコードとしてPythonコードや専用のモジュールを提供しているので、それがそのまま使用できれば効率が良いのにな、と思いました。

IRISが埋め込みPython機能としてWSGIをサポートしたことにより、これが簡単に実現しそうなので、その方法をご紹介したいと思います。

# 導入方法

今回は、IdPとしてOKTAを使用してAuthorization Codeフローを行います。

## OKTAでの設定内容

参考までに、今回使用した環境を後半に記載しています。

## アプリケーションの起動

コンテナ化してありますので、コンテナのビルド環境をお持ちの方は、下記を実行してください。

```
git clone https://github.com/IRISMeister/iris-okta-oidc-wsgi
cd iris-okta-oidc-wsgi
```

python/.env.templateをpython/.envという名前でコピーを作成して、OKTAで得られる設定値を指定してください。

```
AUTH0_CLIENT_ID="0oaxxxxxxx"  
AUTH0_CLIENT_SECRET="qUudxxxxxxxxxxx"
AUTH0_DOMAIN="dev-xxxxx.okta.com/oauth2/default"
```
> AUTH0_CLIENT_ID,AUTH0_CLIENT_SECRETは後述の「アプリケーション追加」で使用する画面から取得できます。
> AUTH0_DOMAINは、後述の「カスタムSCOPE追加」で使用する画面から取得できる発行者URIを設定します。

```
docker compose build
docker compose up -d
```

下記でIRISの管理ポータルにアクセスできます。

> http://localhost:8882/csp/sys/%25CSP.Portal.Home.zen  
> ユーザ名:SuperUser, パスワード:SYS

## WSGI環境での実行
まずは、純粋なWSGI環境での実行を行って、設定が正しくできているかを確認します。コードは[こちら](https://github.com/auth0-samples/auth0-python-web-app/tree/master/01-Login)を使用しました。

>元々はAuth0用ですが、ほぼそのままでOKTAでも使用できました


下記のコマンドでFlaskを起動します。
```
docker compose exec iris python3 /usr/irissys/mgr/python/run.py
```
ブラウザで[メインページ](http://localhost:8889/)にアクセスしてください。

> http://127.0.0.1:8889/ ではリダイレクトに失敗します。

「Login」をクリックするとOKTAのログイン画面が表示されます。OKTAサインアップ時に使用した多要素認証(スマホアプリ)を使用してログインしてください。

うまく動作した場合は、取得したトークンの情報等が表示されます。namespace: USERと表示されている通り、IRISへのアクセスも行っています。
```
Welcome Tomohiro Iwamoto!
Logout

{
    "access_token": "eyJraWQiOi.....",
    "expires_at": 1731482958,
    "expires_in": 3600,
    "id_token": "eyJraWQ......",
    "scope": "email user/*.* profile openid",
    "token_type": "Bearer",
    "userinfo": {
        "amr": [
            "mfa",
            "otp",
            "pwd"
        ],
        "at_hash": "3cRg3plSvDPqGUwEBzefoA",
        "aud": "xxxxx",
        "auth_time": 1731477799,
        "email": "iwamoto@intersystems.com",
        "exp": 1731482958,
        "iat": 1731479358,
        "idp": "xxxxxxxxxx",
        "iss": "https://dev-xxxxxx.okta.com/oauth2/default",
        "jti": "ID.Z0icZKkP61n3WDLgD08q3QxJ4Ags6_rwhrqFX3lAUjs",
        "name": "Tomohiro Iwamoto",
        "nonce": "DYrD0GKQPyXuT6Fni1So",
        "preferred_username": "iwamoto@intersystems.com",
        "sub": "xxxxxx",
        "ver": 1
    }
}
namespace: USER
```

「Logout」をクリックするとOKTAからのログアウトが実行され、最初のページにリダイレクトされます。

## IRIS+WSGI環境での実行

ブラウザで[IRIS+WSGI用のメインページ](http://localhost:8882/csp/sys/wsgi/app/)にアクセスしてください。以降の操作は同じです。

> 同じFlask用のコードを使用していますので、全く同じ動作になります。

## 何が可能になったのか

これは「IRIS+WSGIで何が可能になるか？」という問いと同じですが、本トピックに限定すると、例えばbearer tokenであるアクセストークンを、cookie(flaskのsessionの仕組み)ではなく、IRISのDB上に保存する、他のCSP/RESTアプリケーションに渡す、という応用が考えられます。

元々、CSPやIRISのRESTで作成したアプリケーションがあって、そこにIdP発行のアクセストークンを渡したい、といった用法に向いているアプローチかと思います。

また、IRISでWSGIを実行することにより、gunicornのような運用レベルのWSGI用ウェブサーバを別途立てる必要がなくなります。

## OKTAでの設定内容

今回使用した環境です。

[こちら](https://www.okta.com/jp/free-trial/)のトライアル環境を使用しました。若干画面が変わっていましたが、サインアップ手順は[こちら](https://note.com/oak_gi/n/n886eeef1248b)を参考にしました。登録の際にはMFA(多要素認証)としてスマホが必要です。

ログインすると、次のようなメイン画面が表示されます。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/db.png?raw=true)

以降、アプリケーション追加、カスタムSCOPE追加、認証ポリシー設定などを行っています。

### アプリケーション追加
メニューのアプリケーション->アプリケーションで、flask-code-flowという名称でアプリケーションを追加します。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/app.png?raw=true)

「一般」タブのクライアント資格情報のは下記のようになります。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/app2.png?raw=true)

一般設定は下記のようになります。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/app3.png?raw=true)

ログイン設定は下記のようになります。複数の登録がありますが、これは実行環境に合わせて各々オリジン(ブラウザで指定するURL)が異なるためです。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/app4.png?raw=true)

ログアウト設定は下記のようになります。複数の登録がある理由はログイン設定と同じです。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/app5.png?raw=true)

「サインオン」タブの設定は下記のようになります。サインオン方法としてOpenID Connectが指定されます。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/app6.png?raw=true)

「サインオン」タブの下のほうに「ユーザー認証」というセクションがありますので、そこのポリシーの詳細リンクを押して「認証ポリシー」画面に遷移します。

「認証ポリシー」では、ルールはそのままで、アプリケーションには追加したアプリケーションを「アプリを追加」で追加登録します。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/policy.png?raw=true)

「割り当て」タブのクライアント資格情報のは下記のようになります。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/app7.png?raw=true)

### カスタムSCOPE追加

リソースサーバ用にカスタムのSCOPEを追加します。「セキュリティ」->「API」でdefaultを編集して、オーディエンスとして適当なURL(ここでは http://localhost/csp/healthshare/sc/fhir/r4 )を設定します。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/api0.png?raw=true)

defaultをクリックすると下記の画面に遷移します。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/api.png?raw=true)

「スコープ」タブを選択し、「スコープを追加」を押してカスタムSCOPEを追加します。ここではuser/*.*というスコープを追加しました。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/scope.png?raw=true)

### アクセスポリシー設定

アクセスポリシーを追加します。「セキュリティ」->「API」で認可サーバ:defaultを選択します。「アクセスポリシー」タブを選択し、default policyにアプリケーションを追加します。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/api-policy.png?raw=true)

「ルールを追加」を押して、新しいルールを追加します。以下のような設定にしました。

![](https://github.com/IRISMeister/iris-okta-oidc-wsgi/blob/main/images/api-rule.png?raw=true)


