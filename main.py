import customtkinter as ctk
from database.database import create_db_and_tables

# Import Views
from ui.dashboard_view import DashboardView
from ui.contacts_view import ContactsView

class App(ctk.CTk):
    def __init__(self):
        super().__init__()

        # --- Window Setup ---
        self.title("مدیر کارگاه ۷")
        self.geometry("1100x720")

        # --- Theme and Appearance ---
        # Using Vazirmatn font if available on the system, otherwise a default font.
        self.font_fa = "Vazirmatn"
        ctk.set_appearance_mode("System")  # Modes: "System" (default), "Dark", "Light"
        ctk.set_default_color_theme("blue")  # Themes: "blue" (default), "green", "dark-blue"

        # --- Main Grid Layout (RTL: content on left, sidebar on right) ---
        # 1x2 grid: | content (col 0) | sidebar (col 1) |
        self.grid_columnconfigure(0, weight=1)
        self.grid_columnconfigure(1, weight=0) # Sidebar doesn't expand
        self.grid_rowconfigure(0, weight=1)

        # --- Sidebar Frame ---
        self.sidebar_frame = ctk.CTkFrame(self, width=180, corner_radius=0)
        self.sidebar_frame.grid(row=0, column=1, sticky="nsew")
        self.sidebar_frame.grid_rowconfigure(9, weight=1) # Pushes settings button to bottom

        # Sidebar Title
        self.logo_label = ctk.CTkLabel(self.sidebar_frame, text="مدیر کارگاه", font=ctk.CTkFont(family=self.font_fa, size=20, weight="bold"))
        self.logo_label.grid(row=0, column=0, padx=20, pady=(20, 10))

        # Navigation Buttons
        self.dashboard_button = ctk.CTkButton(self.sidebar_frame, text="پیشخوان", font=ctk.CTkFont(family=self.font_fa, size=14), command=lambda: self.show_view("dashboard"))
        self.dashboard_button.grid(row=1, column=0, padx=20, pady=10)

        self.contacts_button = ctk.CTkButton(self.sidebar_frame, text="مخاطبین", font=ctk.CTkFont(family=self.font_fa, size=14), command=lambda: self.show_view("contacts"))
        self.contacts_button.grid(row=2, column=0, padx=20, pady=10)

        self.employees_button = ctk.CTkButton(self.sidebar_frame, text="کارکنان", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.employees_button_event)
        self.employees_button.grid(row=3, column=0, padx=20, pady=10)

        self.inventory_button = ctk.CTkButton(self.sidebar_frame, text="انبار و خرید", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.inventory_button_event)
        self.inventory_button.grid(row=4, column=0, padx=20, pady=10)

        self.production_button = ctk.CTkButton(self.sidebar_frame, text="تولید", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.production_button_event)
        self.production_button.grid(row=5, column=0, padx=20, pady=10)

        self.sales_button = ctk.CTkButton(self.sidebar_frame, text="فروش", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.sales_button_event)
        self.sales_button.grid(row=6, column=0, padx=20, pady=10)

        self.financials_button = ctk.CTkButton(self.sidebar_frame, text="امور مالی", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.financials_button_event)
        self.financials_button.grid(row=7, column=0, padx=20, pady=10)

        # Settings button at the bottom
        self.settings_button = ctk.CTkButton(self.sidebar_frame, text="تنظیمات", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.settings_button_event)
        self.settings_button.grid(row=10, column=0, padx=20, pady=(10, 20), sticky="s")


        # --- Main Content Frame ---
        self.content_frame = ctk.CTkFrame(self, corner_radius=0, fg_color="transparent")
        self.content_frame.grid(row=0, column=0, sticky="nsew")
        self.content_frame.grid_rowconfigure(0, weight=1)
        self.content_frame.grid_columnconfigure(0, weight=1)

        # --- View Management ---
        self.views = {}

        dashboard_view = DashboardView(self.content_frame)
        self.views["dashboard"] = dashboard_view
        dashboard_view.grid(row=0, column=0, sticky="nsew")

        # Add other views here later
        # e.g., contacts_view = ContactsView(self.content_frame)
        # self.views["contacts"] = contacts_view
        # contacts_view.grid(row=0, column=0, sticky="nsew")

        self.show_view("dashboard")


    def show_view(self, view_name):
        # Hide all views
        for view in self.views.values():
            view.grid_remove()

        # Show the requested view
        view_to_show = self.views.get(view_name)
        if view_to_show:
            view_to_show.grid()
            view_to_show.tkraise()
        else:
            print(f"View '{view_name}' not found.")


    # --- Button Events (Placeholder for others) ---
    def contacts_button_event(self):
        print("Contacts button clicked")

    def employees_button_event(self):
        print("Employees button clicked")

    def inventory_button_event(self):
        print("Inventory button clicked")

    def production_button_event(self):
        print("Production button clicked")

    def sales_button_event(self):
        print("Sales button clicked")

    def financials_button_event(self):
        print("Financials button clicked")

    def settings_button_event(self):
        print("Settings button clicked")


if __name__ == "__main__":
    # Create database and tables if they don't exist
    print("Initializing database...")
    create_db_and_tables()
    print("Database initialized.")

    # Run the application
    app = App()
    app.mainloop()
