import enum
from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    String,
    Float,
    Date,
    Enum,
    ForeignKey,
)
from sqlalchemy.orm import relationship, declarative_base

Base = declarative_base()


# Enum Types based on the spec
class ContactType(enum.Enum):
    customer = "مشتری"
    supplier = "تامین‌کننده"


class EmployeePaymentType(enum.Enum):
    daily = "روزانه"
    hourly = "ساعتی"


class FulfillmentStatus(enum.Enum):
    pending = "در انتظار"
    fulfilled = "آماده شده"


class PaymentStatus(enum.Enum):
    unpaid = "پرداخت نشده"
    partially_paid = "پرداخت ناقص"
    paid = "پرداخت شده"


class DeliveryStatus(enum.Enum):
    undelivered = "تحویل نشده"
    delivered = "تحویل شده"


class PartType(enum.Enum):
    raw = "ماده اولیه"
    assembled = "مونتاژی"


class AssemblyStatus(enum.Enum):
    pending = "در انتظار"
    completed = "تکمیل شده"


# --- Models ---


class Mokhatab(Base):
    __tablename__ = "contacts"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    contact_type = Column(Enum(ContactType), nullable=False)
    phone = Column(String)
    address = Column(String)
    notes = Column(String)

    # Relationships
    kharid_ha = relationship("Kharid", back_populates="tamin_konande")
    sefaresh_foroosh_ha = relationship("SefareshForoosh", back_populates="moshtari")


class Karmand(Base):
    __tablename__ = "employees"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    payment_type = Column(Enum(EmployeePaymentType), nullable=False)
    rate = Column(Float, nullable=False)

    # Relationships
    gozaresh_kar_ha = relationship("GozareshKar", back_populates="karmand")
    pardakht_hoghoogh_ha = relationship("PardakhtHoghoogh", back_populates="karmand")


class GozareshKar(Base):
    __tablename__ = "work_logs"
    id = Column(Integer, primary_key=True, index=True)
    karmand_id = Column(Integer, ForeignKey("employees.id"), nullable=False)
    date = Column(Date, nullable=False)
    hours_worked = Column(Float, default=0)
    overtime_hours = Column(Float, default=0)

    karmand = relationship("Karmand", back_populates="gozaresh_kar_ha")


class InventoryItem(Base):
    __tablename__ = "inventory_items"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    quantity = Column(Float, nullable=False, default=0)
    average_cost = Column(Float, nullable=False, default=0)
    stock_threshold = Column(Float, default=0)

    # Relationships
    transactions = relationship("InventoryTransaction", back_populates="item")
    kharid_items = relationship("KharidItem", back_populates="inventory_item")


class Kharid(Base):
    __tablename__ = "purchases"
    id = Column(Integer, primary_key=True, index=True)
    tamin_konande_id = Column(Integer, ForeignKey("contacts.id"), nullable=False)
    date = Column(Date, nullable=False)

    tamin_konande = relationship("Mokhatab", back_populates="kharid_ha")
    items = relationship("KharidItem", back_populates="kharid")


class KharidItem(Base):
    __tablename__ = "purchase_items"
    id = Column(Integer, primary_key=True, index=True)
    kharid_id = Column(Integer, ForeignKey("purchases.id"), nullable=False)
    inventory_item_id = Column(Integer, ForeignKey("inventory_items.id"), nullable=False)
    quantity = Column(Float, nullable=False)
    cost = Column(Float, nullable=False)

    kharid = relationship("Kharid", back_populates="items")
    inventory_item = relationship("InventoryItem", back_populates="kharid_items")


class SefareshForoosh(Base):
    __tablename__ = "sales_orders"
    id = Column(Integer, primary_key=True, index=True)
    moshtari_id = Column(Integer, ForeignKey("contacts.id"), nullable=False)
    date = Column(Date, nullable=False)
    fulfillment_status = Column(Enum(FulfillmentStatus), default=FulfillmentStatus.pending)
    payment_status = Column(Enum(PaymentStatus), default=PaymentStatus.unpaid)
    delivery_status = Column(Enum(DeliveryStatus), default=DeliveryStatus.undelivered)

    moshtari = relationship("Mokhatab", back_populates="sefaresh_foroosh_ha")
    items = relationship("SefareshForooshItem", back_populates="sefaresh")
    payments = relationship("Pardakht", back_populates="sefaresh")


class SefareshForooshItem(Base):
    __tablename__ = "sales_order_items"
    id = Column(Integer, primary_key=True, index=True)
    sefaresh_id = Column(Integer, ForeignKey("sales_orders.id"), nullable=False)
    # This can be a product or a raw inventory item
    item_name = Column(String, nullable=False)
    quantity = Column(Float, nullable=False)
    price = Column(Float, nullable=False)

    sefaresh = relationship("SefareshForoosh", back_populates="items")


class Pardakht(Base):
    __tablename__ = "payments"
    id = Column(Integer, primary_key=True, index=True)
    sefaresh_id = Column(Integer, ForeignKey("sales_orders.id"), nullable=False)
    date = Column(Date, nullable=False)
    amount = Column(Float, nullable=False)

    sefaresh = relationship("SefareshForoosh", back_populates="payments")


class InventoryTransaction(Base):
    __tablename__ = "inventory_transactions"
    id = Column(Integer, primary_key=True, index=True)
    item_id = Column(Integer, ForeignKey("inventory_items.id"), nullable=False)
    date = Column(Date, nullable=False)
    change_in_quantity = Column(Float, nullable=False)
    reason = Column(String) # e.g., 'purchase', 'sale', 'production_usage', 'adjustment'

    item = relationship("InventoryItem", back_populates="transactions")


class Part(Base):
    __tablename__ = "parts"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    part_type = Column(Enum(PartType), nullable=False)

    # Relationships
    # A part can be a component in many other part recipes
    used_in_recipes = relationship("PartRecipeItem", foreign_keys="[PartRecipeItem.component_part_id]", back_populates="component_part")
    # An assembled part has its own recipe
    recipe_items = relationship("PartRecipeItem", foreign_keys="[PartRecipeItem.assembled_part_id]", back_populates="assembled_part")
    # A part can be a component in many product recipes
    used_in_product_recipes = relationship("ProductRecipeItem", back_populates="part")


class PartRecipeItem(Base):
    __tablename__ = "part_recipe_items"
    id = Column(Integer, primary_key=True, index=True)
    assembled_part_id = Column(Integer, ForeignKey("parts.id"), nullable=False)
    component_part_id = Column(Integer, ForeignKey("parts.id"), nullable=False)
    quantity = Column(Float, nullable=False)

    assembled_part = relationship("Part", foreign_keys=[assembled_part_id], back_populates="recipe_items")
    component_part = relationship("Part", foreign_keys=[component_part_id], back_populates="used_in_recipes")


class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    sale_price = Column(Float, nullable=False)

    recipe = relationship("ProductRecipeItem", back_populates="product")


class ProductRecipeItem(Base):
    __tablename__ = "product_recipe_items"
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    part_id = Column(Integer, ForeignKey("parts.id"), nullable=False)
    quantity = Column(Float, nullable=False)

    product = relationship("Product", back_populates="recipe")
    part = relationship("Part", back_populates="used_in_product_recipes")


class AssemblyOrder(Base):
    __tablename__ = "assembly_orders"
    id = Column(Integer, primary_key=True, index=True)
    part_id = Column(Integer, ForeignKey("parts.id"), nullable=False)
    quantity = Column(Float, nullable=False)
    status = Column(Enum(AssemblyStatus), default=AssemblyStatus.pending)

    part = relationship("Part")


class PardakhtHoghoogh(Base):
    __tablename__ = "salary_payments"
    id = Column(Integer, primary_key=True, index=True)
    karmand_id = Column(Integer, ForeignKey("employees.id"), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    total_salary = Column(Float, nullable=False)

    karmand = relationship("Karmand", back_populates="pardakht_hoghoogh_ha")
    installments = relationship("GhestHoghoogh", back_populates="pardakht_hoghoogh")


class GhestHoghoogh(Base):
    __tablename__ = "salary_installments"
    id = Column(Integer, primary_key=True, index=True)
    pardakht_hoghoogh_id = Column(Integer, ForeignKey("salary_payments.id"), nullable=False)
    date = Column(Date, nullable=False)
    amount = Column(Float, nullable=False)

    pardakht_hoghoogh = relationship("PardakhtHoghoogh", back_populates="installments")


class Hazine(Base):
    __tablename__ = "expenses"
    id = Column(Integer, primary_key=True, index=True)
    description = Column(String, nullable=False)
    date = Column(Date, nullable=False)
    amount = Column(Float, nullable=False)
