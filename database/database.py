from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from .models import Base

# Define the path to the SQLite database file
DATABASE_URL = "sqlite:///workshop_manager.db"

# Create the database engine
# `check_same_thread=False` is needed for SQLite to be used in a multithreaded environment,
# which can be the case in GUI applications.
engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}
)

# Create a configured "Session" class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def create_db_and_tables():
    """
    Creates the database and all tables defined in models.py.
    This function should be called once at the application startup.
    """
    Base.metadata.create_all(bind=engine)

def get_session():
    """
    Returns a new database session.
    """
    return SessionLocal()
