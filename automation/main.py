import functions_framework
import flask

@functions_framework.http
def main(request: flask.Request) -> flask.Response:
    return flask.Response("Narbeh! main.py running", mimetype="text/plain")