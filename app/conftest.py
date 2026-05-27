import sys
import os

sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

# Force testing database before app loads
os.environ["DATABASE_URL"] = "sqlite:///:memory:"