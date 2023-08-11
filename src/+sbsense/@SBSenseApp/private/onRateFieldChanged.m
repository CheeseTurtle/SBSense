function onRateFieldChanged(app, src, event)
    % newFPP = event.Value;
    % FPPSpinner, (FPSField), (SPPField)
    if isnan(app.SPFField.NumericValue)
        app.SPFField.NumericValue = str2num(app.SPFField.Value); %#ok<ST2NM> 
    end
    app.SPPField.Value = app.SPFField.NumericValue * event.Value;
    % app.SPPField.Value = newSPF * app.FPPSpinner.Value;


end

% Superclasses of matlab.ui.control.EditField
    % {'matlab.ui.control.internal.model.ComponentModel'                      }
    % {'matlab.ui.control.internal.model.mixin.EditableComponent'             }
    % {'matlab.ui.control.internal.model.mixin.HorizontallyAlignableComponent'}
    % {'matlab.ui.control.internal.model.mixin.FontStyledComponent'           }
    % {'matlab.ui.control.internal.model.mixin.BackgroundColorableComponent'  }
    % {'matlab.ui.control.internal.model.mixin.PositionableComponent'         }
    % {'matlab.ui.control.internal.model.mixin.EnableableComponent'           }
    % {'matlab.ui.control.internal.model.mixin.VisibleComponent'              }
    % {'matlab.ui.control.internal.model.mixin.TooltipComponent'              }
    % {'matlab.ui.control.internal.model.mixin.PlaceholderComponent'          }
    % {'matlab.ui.control.internal.model.mixin.Layoutable'                    }
    % {'    '            }

% Superclasses of matlab.ui.control.NumericEditField
    % {'matlab.ui.control.internal.model.AbstractNumericComponent'}
    % {'matlab.ui.control.internal.model.mixin.Layoutable'        }
    % {'matlab.ui.control.internal.model.mixin.FocusableComponent'}