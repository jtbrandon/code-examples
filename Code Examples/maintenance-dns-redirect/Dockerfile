FROM python:3.6
COPY DNSUpdater.py /
COPY requirements.txt /

RUN pip install --no-cache --upgrade -r requirements.txt
ENTRYPOINT ["python3", "./DNSUpdater.py" ] 
