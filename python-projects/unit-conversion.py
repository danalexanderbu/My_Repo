import tkinter as tk
from tkinter import ttk
from pint import UnitRegistry, DimensionalityError


# Create a unit registry to handle the conversion
ureg = UnitRegistry()

# Define a function to perform the conversion
def convert_units():
    from_value_str = from_entry.get()
    from_unit = from_option.get()
    to_unit = to_option.get()

    # Ensure that a value was entered
    if not from_value_str.strip():
        result_label.config(text="Please enter a value to convert.")
        return

    # Ensure that the value is a number
    try:
        from_value = float(from_value_str)
    except ValueError:
        result_label.config(text="Invalid value. Please enter a number.")
        return

    # Ensure that units were selected
    if not from_unit or not to_unit:
        result_label.config(text="Please select units.")
        return

    # Perform the conversion
    try:
        to_value = (from_value * ureg(from_unit)).to(ureg(to_unit))
    except DimensionalityError:
        result_label.config(text="Incompatible units.")
        return

    result_label.config(text=f"{from_value} {from_unit} is equal to {to_value.magnitude:.2f} {to_unit}")

# Function to append a number to the entry field
def append_number(number):
    current = from_entry.get()
    from_entry.delete(0, tk.END)
    from_entry.insert(0, current + str(number))

# Create the main window
window = tk.Tk()
window.title("Unit Converter")

# Create a entry field for from_value
from_entry = tk.Entry(window)
from_entry.grid(row=0, column=0, columnspan=4)

# Create number buttons
for i in range(10):
    button = tk.Button(window, text=str(i), command=lambda i=i: append_number(i))
    button.grid(row=1 + i // 3, column=i % 3)

# Create dropdown menus for from_unit and to_unit
units = [
    "mile", "kilometer", "meter", "centimeter", "millimeter", "micrometer",
    "nanometer", "inch", "foot", "yard", "pound", "kilogram", "gram",
    "milligram", "microgram", "ounce", "stone", "long_ton", "tonne",
    "grain", "dram", "hundredweight", "byte", "kilobyte", "megabyte",
    "gigabyte", "terabyte", "petabyte", "exabyte", "zettabyte", "yottabyte",
    "bit", "kilobit", "megabit", "gigabit", "terabit", "petabit", "exabit",
    "zettabit", "yottabit", "liter", "milliliter", "centiliter", "deciliter",
    "gallon", "fluid_ounce", "pint", "quart", "barrel", "cubic_meter",
    "cubic_foot", "cubic_inch", "cubic_yard", "cubic_centimeter", "cubic_millimeter",
    "second", "minute", "hour", "day", "week", "month", "year", "decade",
    "century", "millisecond", "microsecond", "nanosecond", "picosecond", "femtosecond",
    "kelvin", "celsius", "fahrenheit", "rankine", "newton", "pound_force",
    "dyne", "kilopond", "poundal", "joule", "electronvolt", "calorie",
    "british_thermal_unit", "foot_pound", "watt", "horsepower", "foot_pound_per_minute",
    "erg_per_second", "pascal", "bar", "pound_per_square_inch", "torr",
    "atmosphere", "ampere", "milliampere", "microampere", "coulomb_per_second"
]
#using ttk.Combobox instead of tk.OptionMenu because of inablity to change the width of the dropdown menu
from_option = ttk.Combobox(window, values=units)
from_option.set(units[0])  # default value
from_option.grid(row=5, column=0, columnspan=2)

to_option = ttk.Combobox(window, values=units)
to_option.set(units[1])  # default value
to_option.grid(row=5, column=2, columnspan=2)

# Create a button that will trigger the conversion
convert_button = tk.Button(window, text="Convert", command=convert_units)
convert_button.grid(row=6, column=0, columnspan=4)

# Create a label to display the result of the conversion
result_label = tk.Label(window, text="")
result_label.grid(row=7, column=0, columnspan=4)

# Run the application
window.mainloop()