import customtkinter as ctk
from database.database import get_session
from database.models import Mokhatab, ContactType

class ContactModal(ctk.CTkToplevel):
    def __init__(self, master, title, on_save, contact=None):
        super().__init__(master)
        self.font_fa = "Vazirmatn"
        self.db_session = get_session()
        self.on_save_callback = on_save
        self.contact_to_edit = contact

        self.title(title)
        self.geometry("400x500")
        self.resizable(False, False)

        # Make window modal
        self.transient(master)
        self.grab_set()

        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(5, weight=1) # For notes textbox

        # --- Widgets ---
        # Name
        ctk.CTkLabel(self, text="نام:", font=ctk.CTkFont(family=self.font_fa, size=14)).grid(row=0, column=0, padx=20, pady=(20, 5), sticky="e")
        self.name_entry = ctk.CTkEntry(self, justify="right", font=ctk.CTkFont(family=self.font_fa, size=12))
        self.name_entry.grid(row=0, column=0, padx=20, pady=(20, 5), sticky="w", ipadx=30)

        # Type
        ctk.CTkLabel(self, text="نوع:", font=ctk.CTkFont(family=self.font_fa, size=14)).grid(row=1, column=0, padx=20, pady=5, sticky="e")
        contact_types = [ct.value for ct in ContactType]
        self.type_menu = ctk.CTkOptionMenu(self, values=contact_types, font=ctk.CTkFont(family=self.font_fa, size=12), dropdown_font=ctk.CTkFont(family=self.font_fa, size=12))
        self.type_menu.grid(row=1, column=0, padx=20, pady=5, sticky="w", ipadx=30)

        # Phone
        ctk.CTkLabel(self, text="تلفن:", font=ctk.CTkFont(family=self.font_fa, size=14)).grid(row=2, column=0, padx=20, pady=5, sticky="e")
        self.phone_entry = ctk.CTkEntry(self, justify="right", font=ctk.CTkFont(family=self.font_fa, size=12))
        self.phone_entry.grid(row=2, column=0, padx=20, pady=5, sticky="w", ipadx=30)

        # Address
        ctk.CTkLabel(self, text="آدرس:", font=ctk.CTkFont(family=self.font_fa, size=14)).grid(row=3, column=0, padx=20, pady=5, sticky="e")
        self.address_entry = ctk.CTkEntry(self, justify="right", font=ctk.CTkFont(family=self.font_fa, size=12))
        self.address_entry.grid(row=3, column=0, padx=20, pady=5, sticky="w", ipadx=30)

        # Notes
        ctk.CTkLabel(self, text="یادداشت‌ها:", font=ctk.CTkFont(family=self.font_fa, size=14)).grid(row=4, column=0, padx=20, pady=5, sticky="e")
        self.notes_textbox = ctk.CTkTextbox(self, font=ctk.CTkFont(family=self.font_fa, size=12))
        self.notes_textbox.grid(row=5, column=0, padx=20, pady=(0, 10), sticky="nsew")

        # --- Buttons ---
        button_frame = ctk.CTkFrame(self, fg_color="transparent")
        button_frame.grid(row=6, column=0, padx=20, pady=20, sticky="ew")
        button_frame.grid_columnconfigure((0, 1), weight=1)

        cancel_button = ctk.CTkButton(button_frame, text="انصراف", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.destroy)
        cancel_button.grid(row=0, column=0, padx=(0, 5))

        save_button = ctk.CTkButton(button_frame, text="ذخیره", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.save_contact)
        save_button.grid(row=0, column=1, padx=(5, 0))

        if self.contact_to_edit:
            self.fill_form_for_edit()

    def fill_form_for_edit(self):
        self.name_entry.insert(0, self.contact_to_edit.name)
        self.type_menu.set(self.contact_to_edit.contact_type.value)
        self.phone_entry.insert(0, self.contact_to_edit.phone or "")
        self.address_entry.insert(0, self.contact_to_edit.address or "")
        self.notes_textbox.insert("1.0", self.contact_to_edit.notes or "")
        # Lock the type for editing
        self.type_menu.configure(state="disabled")

    def save_contact(self):
        name = self.name_entry.get().strip()
        if not name:
            # Simple validation
            # TODO: Show an error message to the user
            print("Error: Name cannot be empty.")
            return

        try:
            if self.contact_to_edit:
                # Update existing contact
                contact = self.contact_to_edit
            else:
                # Create new contact
                contact = Mokhatab()
                self.db_session.add(contact)

            contact.name = name
            # Type is only set on creation
            if not self.contact_to_edit:
                selected_type_value = self.type_menu.get()
                contact.contact_type = ContactType(selected_type_value)

            contact.phone = self.phone_entry.get().strip()
            contact.address = self.address_entry.get().strip()
            contact.notes = self.notes_textbox.get("1.0", "end-1c").strip()

            self.db_session.commit()

            # Trigger the callback to refresh the parent view
            if self.on_save_callback:
                self.on_save_callback()

            self.destroy()

        except Exception as e:
            # TODO: Show an error message to the user
            print(f"Error saving contact: {e}")
            self.db_session.rollback()
