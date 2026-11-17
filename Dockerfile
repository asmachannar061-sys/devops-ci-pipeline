FROM python:3.12-slim AS test

WORKDIR /app
COPY app.py .
COPY tests/ tests/
RUN python -m unittest discover -s tests -v

FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY app.py .
USER 10001:10001

EXPOSE 8000
CMD ["python", "app.py"]
