"""Python Flask WebApp Auth0 integration example
"""

# https://github.com/auth0-samples/auth0-python-web-app
import json
from os import environ as env
from urllib.parse import quote_plus, urlencode
import sys
sys.path += ['/usr/irissys/lib/python','/usr/irissys/mgr/python']
import iris

from authlib.integrations.flask_client import OAuth
from dotenv import find_dotenv, load_dotenv
from flask import Flask, redirect, render_template, session, url_for

ENV_FILE = find_dotenv()
if ENV_FILE:
    load_dotenv(ENV_FILE)


app = Flask(__name__)
app.secret_key = env.get("APP_SECRET_KEY")


oauth = OAuth(app)

oauth.register(
    "auth0",
    client_id=env.get("AUTH0_CLIENT_ID"),
    client_secret=env.get("AUTH0_CLIENT_SECRET"),
    client_kwargs={
        "scope": "openid profile email user/*.* ",
    },
    server_metadata_url=f'https://{env.get("AUTH0_DOMAIN")}/.well-known/openid-configuration',
)


# Controllers API
@app.route("/")
def home():
    return render_template(
        "home.html",
        session=session.get("user"),
        pretty=json.dumps(session.get("user"), indent=4),
        ns = iris.cls('%SYSTEM.Process').NameSpace(),
    )


@app.route("/callback", methods=["GET", "POST"])
def callback():
    token = oauth.auth0.authorize_access_token()
    session["user"] = token
    session['id_token'] = token['id_token'] # /logout用に保存
    #return redirect("/")
    return redirect(url_for("home", _external=True))


@app.route("/login")
def login():
    return oauth.auth0.authorize_redirect(
        redirect_uri=url_for("callback", _external=True)
    )


@app.route("/logout")
def logout():
    # id_token_hintを使用する方法に変更
    id_token_hint=session['id_token'] 
    session.clear()
    return redirect(
        "https://"
        + env.get("AUTH0_DOMAIN")
        # logoutのエンドポイントに/v1を追加
        + "/v1/logout?"
        + urlencode(
            {
                "post_logout_redirect_uri": url_for("home", _external=True),
                "id_token_hint":id_token_hint
            },
            quote_via=quote_plus,
        )
    )
