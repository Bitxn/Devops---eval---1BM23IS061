FROM python:3.11-slim
WORKDIR /app
# Handout said "COPY ex3-flash-sale.py .", but its CMD runs gunicorn "app:app",
# which imports module `app` (i.e. app.py). A hyphenated name like
# ex3-flash-sale is not an importable Python module, so the file must be app.py.
COPY app.py .
RUN pip install --no-cache-dir flask gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app", "--workers", "1", "--threads", "2"]
