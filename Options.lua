-- ========================================================================== --
-- 										 Trilliax Scrubber                                      --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/trilliaxscrubber       --
-- ========================================================================== --
Scorpio                "TrilliaxScrubber.Options"                        "1.2.0"
-- ========================================================================== --
_AceGUI = LibStub("AceGUI-3.0")
_AceConfig = LibStub("AceConfig-3.0")
_AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
_AceConfigDialog = LibStub("AceConfigDialog-3.0")


_AnchorPoints = {
  ["TOP"] = "TOP",
  ["TOPLEFT"] = "TOPLEFT",
  ["TOPRIGHT"] = "TOPRIGHT",
  ["BOTTOM"] = "BOTTOM",
  ["BOTTOMLEFT"] = "BOTTOMLEFT",
  ["BOTTOMRIGHT"] = "BOTTOMRIGHT",
  ["LEFT"] = "LEFT",
  ["RIGHT"] = "RIGHT",
  ["CENTER"] = "CENTER",
}

local settings = {
  type = "group",
  name = "TrilliaxScrubber - Options",
  childGroups = "tab",
  args = {
    general = {
      type = "group",
      name = "General",
      order = 1,
      args = {
        --enable = {
          --type = "toggle",
          --name = "Enable",
          --order = 1
        --},
        layout = {
          type = "group",
          name = "",
          inline = true,
          args = {
            predictGroup = {
              type = "group",
              name = "Mana Prediction",
              inline = true,
              order = 1,
              args = {
                predictDesc = {
                  type = "description",
                  name = [[Predict the final mana while scrubber is casting (the mana gained is in function of difficulty).
This value computed is used by the Alert Bomb icon and alert you earlier than if this option is disabled.
|cffff0000The Mana Text is not concerned by that and displays the true current mana.|r ]],
                  order = 1,
                },
                predictMana = {
                  type = "toggle",
                  name = "Enable the mana prediction",
                  order = 2,
                  get = function() return  _DB.General.predictMana end,
                  set = function(_, value) _DB.General.predictMana = value end,
                }
              }
            },
            configGroup = {
              type = "group",
              name = "Config Mode",
              inline = true,
              order = 3,
              args = {
                configDesc = {
                  type = "description",
                  name = [[ Toggle the config mode on the enemy nameplates at range.]],
                  order = 2,
                },
                configMode = {
                  type = "execute",
                  name = "Toggle Config Mode",
                  order = 3,
                  func = function() _Addon:ToggleConfigMode() end,
                }
              }
            },
            simGroup = {
              type = "group",
              name = "Simulation Mode",
              inline = true,
              order = 4,
              args = {
                simDesc = {
                  type = "description",
                  name = [[ |cffff0000You need to target a enemy nameplate for the simulation to work.|r ]],
                  order = 4,
                },
                startSimulation = {
                  type = "execute",
                  name = "Start Simulation",
                  order = 5,
                  func = function() _Addon:StartSimulationMode() end,
                }
              }
            }
          }
        }
      }
    },
    infoBox = {
      type = "group",
      name = "Info Box",
      order = 2,
      args = {
        enable = {
          type = "toggle",
          name = "Enable",
          order = 1,
          get = function() return _DB.InfoBox.enabled end,
          set = function(_, value) _DB.InfoBox.enabled = value; if value then _InfoBox:Show() else _InfoBox:Hide() end end,
        },
        group = {
          type = "group",
          name = "",
          order = 2,
          inline = true,
          disabled = function() return not _DB.InfoBox.enabled end,
          args = {
            lock = {
              type = "toggle",
              name = "Lock",
              order = 1,
              get = function() return _DB.InfoBox.locked end,
              set = function(_, value) _DB.InfoBox.locked = value ; _InfoBox:SetLocked(value) end,
            },
            hideTimers = {
              type = "toggle",
              name = "Hide timers",
              order = 3,
              get = function() return _DB.InfoBox.hideTimers end,
              set = function(_, value) _DB.InfoBox.hideTimers = value end,
            },
          }
        }
      }
    },
    manaText = {
      type = "group",
      name = "Mana Text",
      order = 3,
      args = {
        show = {
          type = "toggle",
          name = "Enable",
          order =1,
          get = function() return _DB.ManaText.enabled end,
          set = function(_, value) _DB.ManaText.enabled = value ; _Addon:RefreshAll() end
        },
        position = {
          type = "group",
          name = "Position",
          inline = true,
          order = 2,
          disabled = function() return not _DB.ManaText.enabled end,
          args = {
            offsetX = {
              type = "range",
              name = "Offset X",
              order = 1,
              step = 1,
              min = -300,
              max = 300,
              get = function() return _DB.ManaText.offsetX end,
              set = function(_, value) _DB.ManaText.offsetX = value ; _Addon:RefreshAll() end,
            },
           offsetY = {
             type = "range",
             name = "Offset Y",
             order = 2,
             step = 1,
             min = -300,
             max = 300,
             get = function() return _DB.ManaText.offsetY end,
             set = function(_, value) _DB.ManaText.offsetY = value ; _Addon:RefreshAll() end,
           },
           anchorToBombIcon = {
             type = "toggle",
             name = "Anchor to Bomb Icon",
             order = 3,
             get = function() return _DB.ManaText.anchorToBombIcon end,
             set = function(_, value) _DB.ManaText.anchorToBombIcon = value; _Addon:RefreshAll() end
           },
           anchorFrom = {
             type = "select",
             name = "Anchor from",
             order = 4,
             values = _AnchorPoints,
             get = function() return _DB.ManaText.anchorFrom end,
             set = function(_, value) _DB.ManaText.anchorFrom = value; _Addon:RefreshAll() end
           },
           anchorTo = {
             type = "select",
             name = "Anchor to",
             order = 5,
             values = _AnchorPoints,
             get = function() return _DB.ManaText.anchorTo end,
             set = function(_, value) _DB.ManaText.anchorTo = value; _Addon:RefreshAll() end
           }
          }
        },
        size = {
          type = "range",
          name = "Size",
          order = 1,
          disabled = function() return not _DB.ManaText.enabled end,
          get = function() return _DB.ManaText.size end,
          set = function(_, value) _DB.ManaText.size = value ; _Addon:RefreshAll() end
        },
        color = {
          type = "color",
          name = "Color",
          order = 2,
          disabled = function() return not _DB.ManaText.enabled end,
          get = function()
            local color = _DB.ManaText.color
            return color.r, color.g, color.b
          end,
          set = function(_, r, g, b) _DB.ManaText.color = { r = r, g = g, b = b } ; _Addon:RefreshAll() end
        }
      }
    },
    bomb = {
      type = "group",
      name = "Bomb Icon",
      order = 4,
      args = {
        show = {
          type = "toggle",
          name = "Enable",
          order = 1,
          get = function() return _DB.BombIcon.enabled end,
          set = function(_, value) _DB.BombIcon.enabled = value; _Addon:RefreshAll() end
        },
        width = {
          type = "range",
          name = "Width",
          order = 2,
          disabled = function() return not _DB.BombIcon.enabled end,
          get = function() return _DB.BombIcon.width end,
          set = function(_, value) _DB.BombIcon.width = value ; _Addon:RefreshAll() end,
        },
        height = {
          type = "range",
          name = "Height",
          order = 3,
          disabled = function() return not _DB.BombIcon.enabled end,
          get = function() return _DB.BombIcon.height end,
          set = function(_, value) _DB.BombIcon.height = value ; _Addon:RefreshAll() end,
        },
        position = {
          type = "group",
          name = "Position",
          inline = true,
          order = 4,
          disabled = function() return not _DB.BombIcon.enabled end,
          args = {
            offsetX = {
              type = "range",
              name = "Offset X",
              order = 1,
              step = 1,
              min = -300,
              max = 300,
              set = function(_, value) _DB.BombIcon.offsetX = value; _Addon:RefreshAll() end,
              get = function() return _DB.BombIcon.offsetX end,
            },
           offsetY = {
             type = "range",
             name = "Offset Y",
             order = 2,
             step = 1,
             min = -300,
             max = 300,
             set = function(_, value) _DB.BombIcon.offsetY = value; _Addon:RefreshAll() end,
             get = function() return _DB.BombIcon.offsetY end,
           },
           anchorFrom = {
             type = "select",
             name = "Anchor from",
             order = 4,
             values = _AnchorPoints,
             get = function() return _DB.BombIcon.anchorFrom end,
             set = function(_, value) _DB.BombIcon.anchorFrom = value; _Addon:RefreshAll() end
           },
           anchorTo = {
             type = "select",
             name = "Anchor to",
             order = 5,
             values = _AnchorPoints,
             get = function() return _DB.BombIcon.anchorTo end,
             set = function(_, value) _DB.BombIcon.anchorTo = value; _Addon:RefreshAll() end
           }
          }
        }

      }
    },
    thresholds = {
      type = "group",
      name = "Thresholds",
      order = 5,
      args = {
        low = {
          type = "group",
          name = "Low (4)",
          order = 4,
          inline = true,
          args = {
            enable = {
              type  = "toggle",
              name = "Enable",
              order = 1,
              get = function() return _DB.Thresholds.low.enabled end,
              set = function(_, value) _DB.Thresholds.low.enabled = value end,
            },
            mana = {
              type = "range",
              name = "Mana",
              order = 2,
              disabled = function() return not _DB.Thresholds.low.enabled end,
              get = function() return _DB.Thresholds.low.mana end,
              set = function(_, value) _DB.Thresholds.low.mana = value end,
            },
            color = {
              type = "color",
              name = "Color",
              order = 4,
              disabled = function() return not _DB.Thresholds.low.enabled end,
              get = function()
                local color = _DB.Thresholds.low.color
                return color.r, color.g, color.b
              end,
              set = function(_, r, g, b) _DB.Thresholds.low.color = { r = r, g = g, b = b} end
            }
          }
        },
        medium = {
          type = "group",
          name = "Medium (3)",
          order = 3,
          inline = true,
          args = {
            enable = {
              type  = "toggle",
              name = "Enable",
              order = 1,
              get = function() return _DB.Thresholds.medium.enabled end,
              set = function(_, value) _DB.Thresholds.medium.enabled = value end,
            },
            mana = {
              type = "range",
              name = "Mana",
              order = 2,
              disabled = function() return not _DB.Thresholds.medium.enabled end,
              get = function() return _DB.Thresholds.medium.mana end,
              set = function(_, value) _DB.Thresholds.medium.mana = value end,
            },
            color = {
              type = "color",
              name = "Color",
              order = 4,
              disabled = function() return not _DB.Thresholds.medium.enabled end,
              get = function()
                local color = _DB.Thresholds.medium.color
                return color.r, color.g, color.b
              end,
              set = function(_, r, g, b) _DB.Thresholds.medium.color = { r = r, g = g, b = b} end,
            }
          }
        },
        high = {
          type = "group",
          name = "High (2)",
          order = 2,
          inline = true,
          args = {
            enable = {
              type  = "toggle",
              name = "Enable",
              order = 1,
              get = function() return _DB.Thresholds.high.enabled end,
              set = function(_, value) _DB.Thresholds.high.enabled = value end,
            },
            mana = {
              type = "range",
              name = "Mana",
              order = 2,
              disabled = function() return not _DB.Thresholds.high.enabled end,
              get = function() return _DB.Thresholds.high.mana end,
              set = function(_, value) _DB.Thresholds.high.mana = value end,
            },
            color = {
              type = "color",
              name = "Color",
              order = 4,
              disabled = function() return not _DB.Thresholds.high.enabled end,
              get = function()
                local color = _DB.Thresholds.high.color
                return color.r, color.g, color.b
              end,
              set = function(_, r, g, b) _DB.Thresholds.high.color = { r = r, g = g, b = b} end,
            }
          }
        },
        urgent = {
          type = "group",
          name = "Urgent (1)",
          order = 1,
          inline = true,
          args = {
            enable = {
              type  = "toggle",
              name = "Enable",
              order = 1,
              get = function() return _DB.Thresholds.urgent.enabled end,
              set = function(_, value) _DB.Thresholds.urgent.enabled = value end,
            },
            mana = {
              type = "range",
              name = "Mana",
              order = 2,
              disabled = function() return not _DB.Thresholds.urgent.enabled end,
              get = function() return _DB.Thresholds.urgent.mana end,
              set = function(_, value) _DB.Thresholds.urgent.mana = value end,
            },
            color = {
              type = "color",
              name = "Color",
              order = 4,
              disabled = function() return not _DB.Thresholds.urgent.enabled end,
              get = function()
                local color = _DB.Thresholds.urgent.color
                return color.r, color.g, color.b
              end,
              set = function(_, r, g, b) _DB.Thresholds.urgent.color = { r = r, g = g, b = b} end,
            }
          }
        }
      }
    }

  }
}

local f

function OnLoad(self)

end

function OnEnable(self)
  _AceConfig:RegisterOptionsTable("TrilliaxScrubber", settings)
end

function OnDisable(self)

end

__SlashCmd__  "tsc"
function Open(self)
  if not f then
    f = _AceGUI:Create("Frame")
  end

  _AceConfigDialog:Open("TrilliaxScrubber", f)
end
