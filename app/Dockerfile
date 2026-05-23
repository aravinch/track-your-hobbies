# Dockerfile
# Think of this as a recipe — instructions to build your container

# Start from official Python image — slim = smaller size
FROM python:3.11-slim

# Set working directory inside the container
WORKDIR /app

# Copy requirements first — why? explained below
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the rest of the app
COPY . .

# Tell Docker which port the app runs on
EXPOSE 5000

# Command to run when container starts
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "main:app"]