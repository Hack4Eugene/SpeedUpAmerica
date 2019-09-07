FROM jupyter/datascience-notebook

USER root
RUN apt-get update && apt install -y libmysqlclient-dev

USER jovyan
RUN pip install mysqlclient
