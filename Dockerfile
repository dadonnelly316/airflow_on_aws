FROM python:3.9-slim


ADD app $HOME/app
ADD build $HOME/build

RUN export $(cat $HOME/build/.env | xargs) 
RUN /build/install-airflow.sh

RUN pip install --no-cache-dir -r /build/requierments.txt


