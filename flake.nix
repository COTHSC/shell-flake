{
    description = "Personal shell setup including tmux";

    inputs = { 
        nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

        home-manager = {
            url =  "github:nix-community/home-manager/release-24.05";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, home-manager, nixpkgs }: {
        homeManagerModules.default = {pkgs, ...}: {
            programs.fzf.enable = true;
            programs.fish = {
                enable = true;

                shellAliases = {
                    ll = "ls -l";
                    la = "ls -la";
                    wow = "echo WTaF";
                };

                plugins = [
                {
                    name = "fzf";
                    src = pkgs.fishPlugins.fzf-fish.src;
                }
                ];

                interactiveShellInit = ''
                    set fish_color_command green
                    set fish_color_param normal
                    set fish_color_error red

                    set fish_greeting

                    fish_vi_key_bindings

                    set fish_cursor_default block
                    set fish_cursor_insert line
                    set fish_cursor_replace_one underscore
                    set fish_cursor_visual block

                    function fish_mode_prompt
                    switch $fish_bind_mode
                        case default
                            set_color red
                            echo '[N] '
                            case insert
                            set_color green
                            echo '[I] '
                            case visual
                            set_color yellow
                            echo '[V] '
                            case replace_one
                            set_color magenta
                            echo '[R] '
                            end
                            set_color normal
                            end

                            bind -M insert \cp up-or-search
                            bind -M insert \cn down-or-search
                            bind -M insert \cf forward-char
                            bind -M insert \cb backward-char
                            bind -M insert \ce end-of-line
                            bind -M insert \ca beginning-of-line

                            '';
            };

            programs.tmux = {
                enable = true;
                prefix = "C-a";

# Basic settings
                baseIndex = 1;                # Start windows from 1
                    escapeTime = 0;              # No delay for escape key
                    historyLimit = 50000;
                keyMode = "vi";              # Vi-style keys
                    mouse = true;                # Enable mouse support

# Custom key bindings and settings
                    extraConfig = ''
# Vi copypaste mode
                    bind-key -T copy-mode-vi v send-keys -X begin-selection
                    bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

# Split panes using | and -
                    bind | split-window -h -c "#{pane_current_path}"
                    bind - split-window -v -c "#{pane_current_path}"
                    unbind '"'
                    unbind %

# Switch panes using Alt-vim keys without prefix
                    bind -n M-h select-pane -L
                    bind -n M-l select-pane -R
                    bind -n M-k select-pane -U
                    bind -n M-j select-pane -D

# Resize panes with vim keys
                    bind -r H resize-pane -L 5
                    bind -r J resize-pane -D 5
                    bind -r K resize-pane -U 5
                    bind -r L resize-pane -R 5

# Easier window navigation
                    bind -r C-h previous-window
                    bind -r C-l next-window

# Quick reloads
                    bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

# Status bar styling
                    set -g status-style 'bg=#333333 fg=#5eacd3'
                    set -g status-position top
                    set -g status-left '#[fg=blue,bold]#S '
                    set -g status-right '%H:%M '
                    set -g status-justify centre

# Window styling
                    set -g window-status-current-style 'fg=cyan bold'
                    set -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=cyan]#F '
                    set -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

# Pane borders
                    set -g pane-border-style 'fg=#333333'
                    set -g pane-active-border-style 'fg=#5eacd3'

# Enable true colors
                    set -g default-terminal "tmux-256color"
                    set -ag terminal-overrides ",xterm-256color:RGB"
                    '';


            };
        };

        packages.x86_64-linux.test = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            modules = [ self.homeManagerModules.default {
                home = {
                    stateVersion = "24.05";
                    username = "jcts";
                    homeDirectory = "/home/jcts";
                };
            }
            ];
        };

        devShells.x86_64-linux.default = 
            let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
            pkgs.mkShell {
                packages = with pkgs; [
                    fish
                        tmux
                ];
                shellHook = ''
                    nix run .#test.activationPackage
                    exec fish;
                '';
            };
    };
}
