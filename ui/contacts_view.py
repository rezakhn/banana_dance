import customtkinter as ctk
from database.database import get_session
from database.models import Mokhatab, ContactType
from ui.modals.confirmation_modal import ConfirmationModal

class ContactsView(ctk.CTkFrame):
    def __init__(self, master):
        super().__init__(master, fg_color="transparent")
        self.font_fa = "Vazirmatn"
        self.db_session = get_session()

        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(1, weight=1)

        # --- Top Frame: Title and Add Button ---
        top_frame = ctk.CTkFrame(self, fg_color="transparent")
        top_frame.grid(row=0, column=0, sticky="ew", padx=10, pady=10)
        top_frame.grid_columnconfigure(0, weight=1)

        title_label = ctk.CTkLabel(top_frame, text="مدیریت مخاطبین", font=ctk.CTkFont(family=self.font_fa, size=20, weight="bold"))
        title_label.grid(row=0, column=1, padx=10)

        add_contact_button = ctk.CTkButton(top_frame, text="افزودن مخاطب جدید", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.open_add_contact_modal)
        add_contact_button.grid(row=0, column=0, sticky="w")

        # --- Table Frame ---
        self.table_frame = ctk.CTkScrollableFrame(self)
        self.table_frame.grid(row=1, column=0, sticky="nsew", padx=10, pady=10)
        self.table_frame.grid_columnconfigure((0, 1, 2, 3, 4), weight=1)

        self.create_table_header()
        self.load_contacts()

    def create_table_header(self):
        headers = ["نام", "نوع", "تلفن", "آدرس", "عملیات"]
        for i, header in enumerate(headers):
            header_label = ctk.CTkLabel(self.table_frame, text=header, font=ctk.CTkFont(family=self.font_fa, size=14, weight="bold"), bg_color="gray20")
            header_label.grid(row=0, column=i, sticky="ew", padx=1, pady=1)

    def load_contacts(self):
        # Clear existing rows first (skip header)
        for widget in self.table_frame.winfo_children():
            if int(widget.grid_info()["row"]) > 0:
                widget.destroy()

        try:
            contacts = self.db_session.query(Mokhatab).order_by(Mokhatab.name).all()
            for i, contact in enumerate(contacts, start=1):
                # Name
                name_label = ctk.CTkLabel(self.table_frame, text=contact.name, font=ctk.CTkFont(family=self.font_fa, size=12))
                name_label.grid(row=i, column=0, sticky="ew", padx=1, pady=1)
                # Type
                type_label = ctk.CTkLabel(self.table_frame, text=contact.contact_type.value, font=ctk.CTkFont(family=self.font_fa, size=12))
                type_label.grid(row=i, column=1, sticky="ew", padx=1, pady=1)
                # Phone
                phone_label = ctk.CTkLabel(self.table_frame, text=contact.phone or "---", font=ctk.CTkFont(family=self.font_fa, size=12))
                phone_label.grid(row=i, column=2, sticky="ew", padx=1, pady=1)
                # Address
                address_label = ctk.CTkLabel(self.table_frame, text=contact.address or "---", font=ctk.CTkFont(family=self.font_fa, size=12))
                address_label.grid(row=i, column=3, sticky="ew", padx=1, pady=1)
                # Actions
                actions_frame = ctk.CTkFrame(self.table_frame, fg_color="transparent")
                actions_frame.grid(row=i, column=4, sticky="ew")
                edit_button = ctk.CTkButton(actions_frame, text="ویرایش", width=60, font=ctk.CTkFont(family=self.font_fa, size=11), command=lambda c=contact: self.open_edit_contact_modal(c))
                edit_button.pack(side="right", padx=5)
                delete_button = ctk.CTkButton(actions_frame, text="حذف", width=60, fg_color="red", hover_color="darkred", font=ctk.CTkFont(family=self.font_fa, size=11), command=lambda c=contact: self.delete_contact(c))
                delete_button.pack(side="right", padx=5)

        except Exception as e:
            print(f"Error loading contacts: {e}")
            error_label = ctk.CTkLabel(self.table_frame, text="خطا در بارگذاری مخاطبین")
            error_label.grid(row=1, column=0, columnspan=5)

    def open_add_contact_modal(self):
        from ui.modals.contact_modal import ContactModal
        modal = ContactModal(self, title="افزودن مخاطب جدید", on_save=self.load_contacts)
        # self.wait_window(modal) is implicitly handled by Toplevel grab_set

    def open_edit_contact_modal(self, contact):
        from ui.modals.contact_modal import ContactModal
        modal = ContactModal(self, title=f"ویرایش {contact.name}", on_save=self.load_contacts, contact=contact)
        # self.wait_window(modal)

    def delete_contact(self, contact):
        modal = ConfirmationModal(self, title="تایید حذف", message=f"آیا از حذف مخاطب '{contact.name}' مطمئن هستید؟")
        if modal.get_result():
            try:
                # Check for related records before deleting
                if contact.kharid_ha or contact.sefaresh_foroosh_ha:
                    # Cannot delete, show an error message
                    error_modal = ConfirmationModal(self, title="خطا در حذف", message="این مخاطب دارای سوابق خرید یا فروش است و قابل حذف نیست.\nفقط می‌توانید آن را غیرفعال کنید (ویژگی آینده).")
                    return

                self.db_session.delete(contact)
                self.db_session.commit()
                self.load_contacts()
            except Exception as e:
                print(f"Error deleting contact: {e}")
                self.db_session.rollback()
                # TODO: Show an error message to the user
