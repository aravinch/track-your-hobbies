# Dockerfile
# Start from official Python image — slim = smaller size
FROM python:3.11-slim

# Set working directory inside the container
WORKDIR /app

# Install ODBC Driver 18 for SQL Server
RUN apt-get update && apt-get install -y \
        curl \
        gnupg2 \
        apt-transport-https \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
        > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first — Docker layer caching
# If requirements.txt unchanged, Docker skips pip install on next build
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the rest of the app
COPY . .

# Tell Docker which port the app runs on
EXPOSE 5000

# CMD always last — command to run when container starts
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "main:app"]