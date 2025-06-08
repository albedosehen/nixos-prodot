{pkgs, ...}: {
  home.packages = [pkgs.btop];
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "Default";
      theme_background = false;
      vim_keys = true;
      rounded_corners = true;
      graph_symbol = "braille";
      shown_boxes = "cpu mem net proc";
      update_ms = 2000;
      proc_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = false;
      check_temp = true;
      draw_clock = "%X";
      background_update = true;
      custom_cpu_name = "";
      disks_filter = "";
      mem_graphs = true;
      show_swap = true;
      swap_disk = true;
      show_disks = true;
      only_physical = true;
      use_fstab = false;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = false;
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_color_fixed = false;
      net_sync = false;
      show_battery = true;
      log_level = "WARNING";
    };
  };
}
