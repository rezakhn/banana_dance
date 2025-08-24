import customtkinter as ctk
from database.database import get_session
from database.models import Karmand, SefareshForoosh, InventoryItem, FulfillmentStatus

class DashboardView(ctk.CTkFrame):
    def __init__(self, master):
        super().__init__(master, fg_color="transparent")
        self.font_fa = "Vazirmatn"
        self.db_session = get_session()

        # Configure grid layout: 2x3 for stat cards, then alerts, then chart
        self.grid_columnconfigure((0, 1, 2), weight=1)
        self.grid_rowconfigure(0, weight=0) # Stat cards
        self.grid_rowconfigure(1, weight=0) # Alerts
        self.grid_rowconfigure(2, weight=1) # Chart

        # --- Stat Cards ---
        self.create_stat_cards()

        # --- Alerts Panel ---
        self.create_alerts_panel()

        # --- Sales Chart (Placeholder) ---
        self.chart_frame = ctk.CTkFrame(self)
        self.chart_frame.grid(row=2, column=0, columnspan=3, sticky="nsew", padx=10, pady=10)
        self.chart_label = ctk.CTkLabel(self.chart_frame, text="نمودار روند فروش (در آینده)", font=ctk.CTkFont(family=self.font_fa, size=16))
        self.chart_label.pack(expand=True)

        # Load data from DB
        self.update_stats()
        self.update_alerts()

    def create_stat_cards(self):
        # Frame for all stat cards
        stats_frame = ctk.CTkFrame(self, fg_color="transparent")
        stats_frame.grid(row=0, column=0, columnspan=3, sticky="nsew", padx=0, pady=0)
        stats_frame.grid_columnconfigure((0, 1, 2, 3), weight=1)

        # Card 1: Total Employees
        self.employees_card = StatCard(stats_frame, "تعداد کارکنان", "0")
        self.employees_card.grid(row=0, column=3, sticky="nsew", padx=10, pady=10)

        # Card 2: Pending Orders
        self.pending_orders_card = StatCard(stats_frame, "سفارشات در انتظار", "0")
        self.pending_orders_card.grid(row=0, column=2, sticky="nsew", padx=10, pady=10)

        # Card 3: Unpaid Amount (Placeholder)
        self.unpaid_card = StatCard(stats_frame, "مبلغ پرداخت نشده", "۰ تومان")
        self.unpaid_card.grid(row=0, column=1, sticky="nsew", padx=10, pady=10)

        # Card 4: Gross Profit (Placeholder)
        self.profit_card = StatCard(stats_frame, "سود ناخالص", "۰ تومان")
        self.profit_card.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)

    def create_alerts_panel(self):
        self.alerts_frame = ctk.CTkFrame(self)
        self.alerts_frame.grid(row=1, column=0, columnspan=3, sticky="nsew", padx=10, pady=10)

        title = ctk.CTkLabel(self.alerts_frame, text="⚠️ هشدارها", font=ctk.CTkFont(family=self.font_fa, size=16, weight="bold"), justify="right")
        title.pack(anchor="ne", padx=10, pady=5)

        self.alerts_text_widget = ctk.CTkLabel(self.alerts_frame, text="در حال بارگذاری هشدارها...", justify="right", font=ctk.CTkFont(family=self.font_fa, size=12))
        self.alerts_text_widget.pack(fill="x", padx=10, pady=(0, 10))

    def update_stats(self):
        try:
            employee_count = self.db_session.query(Karmand).count()
            pending_orders_count = self.db_session.query(SefareshForoosh).filter(SefareshForoosh.fulfillment_status == FulfillmentStatus.pending).count()

            self.employees_card.set_value(str(employee_count))
            self.pending_orders_card.set_value(str(pending_orders_count))
            # Other stats will be updated later
        except Exception as e:
            print(f"Error updating stats: {e}")
            self.employees_card.set_value("خطا")
            self.pending_orders_card.set_value("خطا")

    def update_alerts(self):
        alerts = []
        try:
            # Low stock items
            low_stock_items = self.db_session.query(InventoryItem).filter(InventoryItem.quantity < InventoryItem.stock_threshold).all()
            if low_stock_items:
                item_names = ", ".join([item.name for item in low_stock_items])
                alerts.append(f"کالاهای با موجودی کم: {item_names}")

            # TODO: Add other alerts like old unpaid orders

            if not alerts:
                alerts.append("موردی برای هشدار وجود ندارد.")

            self.alerts_text_widget.configure(text="\n".join(f"- {alert}" for alert in alerts))

        except Exception as e:
            print(f"Error updating alerts: {e}")
            self.alerts_text_widget.configure(text="خطا در دریافت هشدارها.")


class StatCard(ctk.CTkFrame):
    """A reusable card for displaying a title, a value, and an icon."""
    def __init__(self, master, title: str, value: str):
        super().__init__(master)
        self.font_fa = "Vazirmatn"

        self.grid_columnconfigure(0, weight=1)

        self.title_label = ctk.CTkLabel(self, text=title, font=ctk.CTkFont(family=self.font_fa, size=14))
        self.title_label.grid(row=0, column=0, padx=15, pady=(10, 5), sticky="e")

        self.value_label = ctk.CTkLabel(self, text=value, font=ctk.CTkFont(size=22, weight="bold"))
        self.value_label.grid(row=1, column=0, padx=15, pady=(5, 10), sticky="e")

    def set_value(self, new_value: str):
        self.value_label.configure(text=new_value)
