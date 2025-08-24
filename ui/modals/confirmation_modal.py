import customtkinter as ctk

class ConfirmationModal(ctk.CTkToplevel):
    def __init__(self, master, title="تایید", message="آیا مطمئن هستید؟"):
        super().__init__(master)
        self.font_fa = "Vazirmatn"
        self.result = False  # Default to False (No/Cancel)

        self.title(title)
        self.geometry("350x150")
        self.resizable(False, False)

        # Make window modal
        self.transient(master)
        self.grab_set()

        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)

        main_frame = ctk.CTkFrame(self, fg_color="transparent")
        main_frame.grid(row=0, column=0, sticky="nsew", padx=20, pady=20)
        main_frame.grid_columnconfigure((0, 1), weight=1)
        main_frame.grid_rowconfigure((0,1), weight=1)


        message_label = ctk.CTkLabel(main_frame, text=message, font=ctk.CTkFont(family=self.font_fa, size=14), wraplength=300, justify="right")
        message_label.grid(row=0, column=0, columnspan=2, pady=(0, 20))

        no_button = ctk.CTkButton(main_frame, text="خیر", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.on_no)
        no_button.grid(row=1, column=0, padx=(0, 5), sticky="ew")

        yes_button = ctk.CTkButton(main_frame, text="بله", fg_color="red", hover_color="darkred", font=ctk.CTkFont(family=self.font_fa, size=14), command=self.on_yes)
        yes_button.grid(row=1, column=1, padx=(5, 0), sticky="ew")

        # Wait for the user to make a choice
        self.wait_window()

    def on_yes(self):
        self.result = True
        self.destroy()

    def on_no(self):
        self.result = False
        self.destroy()

    def get_result(self):
        return self.result
