FROM jupyter/datascience-notebook:1386e2046833

USER root
RUN apt-get update && apt install -y libmysqlclient-dev

USER jovyan
RUN pip install mysqlclient ipython-sql mapboxgl geojson shapely
