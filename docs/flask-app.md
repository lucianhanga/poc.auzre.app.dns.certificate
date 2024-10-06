
# Prepare the environment

## Create a virtual environment

```bash
python -m venv venv
source venv/bin/activate
```

## Install the dependencies

```bash
pip install flask
pip install gunicorn
```

## prepare the dependencies file

```bash
pip freeze > requirements.txt
```

# Create the Flask app

## Create the app

```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```
