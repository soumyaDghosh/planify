/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Layouts.LabelRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid widget_color;
    private Gtk.Grid handle_grid;
    private Gtk.EventBox labelrow_eventbox;

    public LabelRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {
        get_style_context ().add_class ("selectable-item");
        
        widget_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            height_request = 12,
            width_request = 12
        };

        unowned Gtk.StyleContext widget_color_context = widget_color.get_style_context ();
        widget_color_context.add_class ("label-color");

        name_label = new Gtk.Label (label.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        count_label = new Gtk.Label (label.label_count.to_string ()) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 6
        };
        count_label.get_style_context ().add_class ("dim-label");
        count_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        count_revealer = new Gtk.Revealer () {
            reveal_child = int.parse (count_label.label) > 0
        };
        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.add (count_label);

        var labelrow_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3
        };
        labelrow_grid.add (widget_color);
        labelrow_grid.add (name_label);

        handle_grid = new Gtk.Grid ();
        handle_grid.add (labelrow_grid);
        handle_grid.add (count_revealer);

        labelrow_eventbox = new Gtk.EventBox ();
        labelrow_eventbox.get_style_context ().add_class ("transition");
        labelrow_eventbox.add (handle_grid);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (labelrow_eventbox);

        add (main_revealer);

        update_request ();
        
        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        label.updated.connect (() => {
            update_request ();
        });

        labelrow_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Timeout.add (120, () => {
                    if (main_revealer.reveal_child) {
                        Planner.event_bus.pane_selected (PaneType.LABEL, label.id_string);
                    }
                    return GLib.Source.REMOVE;
                });
                return false;
            } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                build_content_menu ();
                return false;
            }

            return false;
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.LABEL && label.id_string == id) {
                labelrow_eventbox.get_style_context ().add_class ("selectable-item-selected");
            } else {
                labelrow_eventbox.get_style_context ().remove_class ("selectable-item-selected");
            }
        });

        label.label_count_updated.connect (() => {
            count_label.label = label.label_count.to_string ();
            count_revealer.reveal_child = int.parse (count_label.label) > 0;
        });
    }

    public void update_request () {
        name_label.label = label.name;
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    private void build_content_menu () {
        var menu = new Dialogs.ContextMenu.Menu ();

        var edit_item = new Dialogs.ContextMenu.MenuItem (("Edit label"), "planner-edit");

        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete label"), "planner-trash");
    
        var delete_item_context = delete_item.get_style_context ();
        delete_item_context.add_class ("menu-item-danger");

        menu.add_item (edit_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (delete_item);

        menu.popup ();

        delete_item.activate_item.connect (() => {
            menu.hide_destroy ();
        });

        edit_item.clicked.connect (() => {
            menu.hide_destroy ();
            var dialog = new Dialogs.Label (label);
            dialog.show_all ();
        });
    }
}