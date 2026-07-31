#!/usr/bin/env python3
"""Small GUI to reorder/add/remove PearDock launcher items in
plasma-org.kde.plasma.desktop-appletsrc without touching anything else
in the file."""

import os
import re
import shutil
import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog, ttk

SECTION_RE = re.compile(r"^\[Containments\]\[(\d+)\]\[Applets\]\[(\d+)\]$")
APPLICATIONS_DIR = "/usr/share/applications"


def default_target():
    return os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "etc", "skel", ".config", "plasma-org.kde.plasma.desktop-appletsrc",
    )


def find_launchers_line(lines):
    """Find the line index of `launchers=` inside the PearDock applet's
    [Configuration][General] section. Returns None if not found."""
    cont_id = applet_id = None
    for i, line in enumerate(lines):
        stripped = line.strip()
        m = SECTION_RE.match(stripped)
        if m:
            cont_id, applet_id = m.group(1), m.group(2)
            continue
        if stripped == "plugin=PearDock" and cont_id is not None:
            target_section = f"[Containments][{cont_id}][Applets][{applet_id}][Configuration][General]"
            in_target = False
            for j in range(i, len(lines)):
                s = lines[j].strip()
                if s == target_section:
                    in_target = True
                    continue
                if in_target:
                    if s.startswith("[") and s.endswith("]"):
                        break
                    if s.startswith("launchers="):
                        return j
            cont_id = applet_id = None
    return None


class DockEditor(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("PearDock item editor")
        self.geometry("560x420")

        self.path = default_target()
        self.lines = []
        self.launcher_idx = None
        self.items = []

        self._build_ui()
        self.load(self.path)

    def _build_ui(self):
        top = ttk.Frame(self, padding=8)
        top.pack(fill="x")
        self.path_label = ttk.Label(top, text="", anchor="w")
        self.path_label.pack(side="left", fill="x", expand=True)
        ttk.Button(top, text="Open...", command=self.open_file).pack(side="right")

        mid = ttk.Frame(self, padding=8)
        mid.pack(fill="both", expand=True)

        self.listbox = tk.Listbox(mid, activestyle="dotbox")
        self.listbox.pack(side="left", fill="both", expand=True)
        sb = ttk.Scrollbar(mid, orient="vertical", command=self.listbox.yview)
        sb.pack(side="left", fill="y")
        self.listbox.config(yscrollcommand=sb.set)

        btns = ttk.Frame(mid, padding=(8, 0))
        btns.pack(side="left", fill="y")
        ttk.Button(btns, text="Add app...", command=self.add_app).pack(fill="x", pady=2)
        ttk.Button(btns, text="Add custom...", command=self.add_custom).pack(fill="x", pady=2)
        ttk.Button(btns, text="Remove", command=self.remove_item).pack(fill="x", pady=2)
        ttk.Button(btns, text="Up", command=lambda: self.move(-1)).pack(fill="x", pady=(16, 2))
        ttk.Button(btns, text="Down", command=lambda: self.move(1)).pack(fill="x", pady=2)

        bottom = ttk.Frame(self, padding=8)
        bottom.pack(fill="x")
        ttk.Button(bottom, text="Save", command=self.save).pack(side="right")
        ttk.Button(bottom, text="Reload", command=lambda: self.load(self.path)).pack(side="right", padx=6)

    def load(self, path):
        if not os.path.exists(path):
            messagebox.showerror("Not found", f"File not found:\n{path}")
            return
        with open(path, "r", encoding="utf-8") as f:
            self.lines = f.readlines()
        idx = find_launchers_line(self.lines)
        if idx is None:
            messagebox.showerror("Not found", "No PearDock launchers= entry in this file.")
            self.items = []
            self.launcher_idx = None
        else:
            self.launcher_idx = idx
            value = self.lines[idx].split("=", 1)[1].rstrip("\n")
            self.items = [v for v in value.split(",") if v != ""]
        self.path = path
        self.path_label.config(text=path)
        self.refresh_listbox()

    def open_file(self):
        p = filedialog.askopenfilename(
            initialdir=os.path.dirname(self.path),
            initialfile=os.path.basename(self.path),
        )
        if p:
            self.load(p)

    def refresh_listbox(self):
        self.listbox.delete(0, "end")
        for item in self.items:
            self.listbox.insert("end", item)

    def selected_index(self):
        sel = self.listbox.curselection()
        return sel[0] if sel else None

    def add_app(self):
        if not os.path.isdir(APPLICATIONS_DIR):
            messagebox.showerror("Missing", f"{APPLICATIONS_DIR} not found.")
            return
        desktop_files = sorted(
            f for f in os.listdir(APPLICATIONS_DIR) if f.endswith(".desktop")
        )
        win = tk.Toplevel(self)
        win.title("Pick application")
        win.geometry("360x420")
        lb = tk.Listbox(win)
        lb.pack(fill="both", expand=True, padx=8, pady=8)
        for f in desktop_files:
            lb.insert("end", f)

        def confirm():
            sel = lb.curselection()
            if not sel:
                return
            entry = f"applications:{desktop_files[sel[0]]}"
            self.items.append(entry)
            self.refresh_listbox()
            win.destroy()

        ttk.Button(win, text="Add", command=confirm).pack(pady=(0, 8))

    def add_custom(self):
        value = simpledialog.askstring(
            "Add custom entry",
            "Launcher entry (e.g. preferred://browser or file:///path/to/app.desktop):",
        )
        if value:
            self.items.append(value.strip())
            self.refresh_listbox()

    def remove_item(self):
        i = self.selected_index()
        if i is None:
            return
        del self.items[i]
        self.refresh_listbox()

    def move(self, delta):
        i = self.selected_index()
        if i is None:
            return
        j = i + delta
        if j < 0 or j >= len(self.items):
            return
        self.items[i], self.items[j] = self.items[j], self.items[i]
        self.refresh_listbox()
        self.listbox.selection_set(j)

    def save(self):
        if self.launcher_idx is None:
            messagebox.showerror("Nothing to save", "No launchers= line was found.")
            return
        backup = self.path + ".bak"
        shutil.copy2(self.path, backup)
        self.lines[self.launcher_idx] = "launchers=" + ",".join(self.items) + "\n"
        with open(self.path, "w", encoding="utf-8") as f:
            f.writelines(self.lines)
        messagebox.showinfo("Saved", f"Saved.\nBackup: {backup}")


if __name__ == "__main__":
    DockEditor().mainloop()
