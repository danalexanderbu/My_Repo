import re
import tkinter as tk
from tkinter import messagebox

class RegexGenerator:
    def __init__(self):
        self.regex = ""

    def add_literal(self, literal):
        self.regex += literal
        return self

    def add_any_char(self):
        self.regex += "."
        return self

    def add_digit(self):
        self.regex += "\d"
        return self

    def add_whitespace(self):
        self.regex += "\s"
        return self

    def start_group(self):
        self.regex += "("
        return self

    def end_group(self):
        self.regex += ")"
        return self

    def compile(self):
        return re.compile(self.regex)


class Application(tk.Frame):
    def __init__(self, master=None):
        super().__init__(master)
        self.master = master
        self.grid()
        self.create_widgets()

    def create_widgets(self):
        self.regex_gen = RegexGenerator()

        # Button to add a literal
        self.add_literal_button = tk.Button(self)
        self.add_literal_button["text"] = "Add Literal"
        self.add_literal_button["command"] = self.add_literal
        self.add_literal_button.grid(row=0, column=0)

        # Entry field to input literal
        self.literal_entry = tk.Entry(self)
        self.literal_entry.grid(row=0, column=1)

        # Button to compile regex
        self.compile_button = tk.Button(self)
        self.compile_button["text"] = "Compile Regex"
        self.compile_button["command"] = self.compile_regex
        self.compile_button.grid(row=1, column=0, columnspan=2)

    def add_literal(self):
        literal = self.literal_entry.get()
        self.regex_gen.add_literal(literal)
        messagebox.showinfo("Regex", f"Current regex: {self.regex_gen.regex}")

    def compile_regex(self):
        try:
            self.regex = self.regex_gen.compile()
            messagebox.showinfo("Regex", f"Current regex: {self.regex_gen.regex}")
        except re.error as e:
            messagebox.showerror("Error", f"Failed to compile regex: {e}")
root = tk.Tk()
app = Application(master=root)
app.mainloop()
