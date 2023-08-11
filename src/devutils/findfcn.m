% [Fs,fns,pns] or [Packs,fnsByPack] -- Does NOT include methods defined in
% classes
function varargout = findfcn(pat,opts)
arguments(Input)
    pat (1,:) char = char.empty(1,0);
    opts.PatternIncludesPackageName  logical = false;
    opts.PackageNamePattern char = char.empty();
    opts.FcnNamePattern char = char.empty();
    opts.IgnoreCase logical = false;
    opts.Abstract {mustBeMember(opts.Abstract, {'include', 'exclude', 'require'})} = 'include';
    opts.Hidden {mustBeMember(opts.Hidden, {'include', 'exclude', 'require'})} = 'include';
    opts.Sealed {mustBeMember(opts.Sealed, {'include', 'exclude', 'require'})} = 'include';
    opts.SearchAllInMem logical = true;
    opts.SearchAllPackages logical = false;
    opts.CompleteNames logical = false;
end

if isempty(pat)
    assert(~isempty(opts.FcnNamePattern) || ~isempty(opts.PackageNamePattern));
else
    if opts.PatternIncludesPackageName
        wc = "[^.]*";
    else
        wc = ".*";
    end
    if ~startsWith(pat, "^"|".*"|".+")
        pat = '^'+wc+pat;
    end
    if ~endsWith(pat, "$"|".*"|".+")
        pat = pat+wc+'$';
    end
end

% fprintf('Pat: "%s"\n', pat);
%if opts.SearchAllInMem
%    [~,~,cns2] = inmem();
%    cns2 = setdiff(cns2, cns1, 'stable'); % cns2 = cns2';
%    cs2 = cellfun(@meta.class.fromName, cns2, 'UniformOutput', false);
%    [cs2, msk2] = filterclasses([cs2{:}], pat, opts.IgnoreCase, ...
%        opts.Abstract, opts.Hidden, opts.Sealed, opts.Enum, ...
%        opts.HandleCompat, opts.MinInferiors, opts.MinSuperiors, ...
%        true);
%    cns2 = cns2(msk2);
%    cs = [cs cs2];
%    cns = [ cns(:) ; cns2(:) ];
%end

if opts.SearchAllPackages
    %opts.SearchAllPackages = false;
    error('Searching all packages is currently not implemented.\n');
end

if opts.SearchAllInMem
    if opts.SearchAllPackages
        fprintf('Warning: Not completely implemented!\n');
        packs = meta.package.getAllPackages();
        allPackNames = ...
            cellfun(@(x) string(x.Name), packs, 'UniformOutput', true);
        %hasDDMask = cellfun(@(x) ~strcmp('',x.Description), packs);
        %noSubpacksMask = cellfun(@(x) isempty(x.Packages), packs);
        %childlessPacks = packs(noSubpacksMask);
        %nodpacks = packs(~hasDDMask);
        % string({nodpacks{1}.ClassList.Name}')
        numPacks = length(allPackNames);
        numFuts = fix(numPacks/75);
        nextIdx = numFuts*75 + 1;
        
        futs = parallel.Future.empty(0,numFuts+1);
        % classes = cell(numPacks);
        % classes = cell(numFuts+1);
        idxs = 1:75;
        for i=1:numFuts
            futs(i) = parfeval(backgroundPool, @getPacksClasses, 1, ...
                cellfun(@struct, packs(idxs), 'UniformOutput', false));
            idxs = idxs + 75;
        end
        futs(numFuts+1) = parfeval(backgroundPool, @getPacksClasses, 1, ...
            packs(nextIdx:end));
        stats = [futs.State];
        fprintf('Waiting for (%d+%d)/%d of %d futs to finish (timeout: 15s)...', ...
            sum(contains(stats,'queued')), ...
            sum(contains(stats,'running')), ...
            sum(~contains(stats,'unavailable')), ...
            numFuts+1);
        TF = wait(futs, "finished", 15);
        if ~TF
            cancel(futs);
            fprintf('..failed.\n');
            Fs = [];
            return;
        end
        Ccell = fetchOutputs(futs, 'UniformOutput', false);
    else
        if opts.CompleteNames
            [fullFcnNames,~,~] = inmem("-completenames");
        else
            [fullFcnNames,~,~] = inmem();
        end
        splitNames = cellfun(@(x) string(strsplit(x, ...
            {'\.(?=[^.]+$)'}, "DelimiterType", "RegularExpression")), ...
            fullFcnNames, 'UniformOutput', false);
        msk = cellfun(@(x) size(x,2)==2, splitNames);
        fcnNamesWithoutPack = splitNames(~msk); % Can assume have len. 1
        splitNamesWithPack = splitNames(msk);
        packNames = cellfun(@(x) x(1), splitNamesWithPack);
        uniquePackNames = unique(packNames);
        uniquePacks = cellfun(@meta.package.fromName, uniquePackNames, ...
            'UniformOutput', false);
        uniquePacks2 = cellfun(@(p) [p.PackageList], ...
            uniquePacks, 'UniformOutput', false);
        uniquePacks = vertcat(uniquePacks{:},uniquePacks2{:});
        [~, uniqueIdxs] = unique({uniquePacks.Name});
        uniquePacks = uniquePacks(uniqueIdxs);
        Ccell = {uniquePacks.ClassList};
        Ccell = [ Ccell(:) ; cellfun(@meta.class.fromName, ...
            fcnNamesWithoutPack, 'UniformOutput', false)];
    end
    Fs = vertcat(Ccell{:})';
else
    Fs = [meta.class.getAllClasses{:}];
    % TODO
    %cns = {cs.Name};
end
fns = {Fs.Name};
%fprintf('Num cns: %d\n', numel(cns));

if opts.PatternIncludesPackageName
    %fprintf('cns: %s\n', formattedDisplayText(cns));
    msk = matches(fns, regexpPattern(pat, "IgnoreCase", opts.IgnoreCase));
    %fprintf('msk sum: %d\n', sum(msk));
    fns = fns(msk)';
    Fs = Fs(msk)';
elseif isempty(opts.PackageNamePattern)
    opts.ClassNamePattern = pat;
end

if ~isempty(opts.PackageNamePattern) || ...
        (~isempty(opts.ClassNamePattern) && ~opts.PatternIncludesPackageName)
    splitNames = cellfun(@(x) string(strsplit(x, ...
        {'\.(?=[^.]+$)'}, "DelimiterType", "RegularExpression")), ...
        cellstr(fns), 'UniformOutput', false);
    % fprintf('Num splitNames: %d\n', numel(splitNames));
    msk = cellfun(@(x) size(x,2)==2, splitNames);
    % fprintf('msk sum: %d\n', sum(msk));
    splitNamesWithPack = splitNames(msk);

    if ~isempty(opts.PackageNamePattern)
        % splitNames = splitNames(msk);
        pat1 = regexpPattern(opts.PackageNamePattern, ...
                "IgnoreCase", opts.IgnoreCase, "Anchors", "text");
        if opts.ClassNamePattern
            pat2 = regexpPattern(opts.ClassNamePattern, ...
                "IgnoreCase", opts.IgnoreCase, "Anchors", "text");
            msk2 = cellfun(@(pcn) ...
                matches(pcn(1), pat1) & matches(pcn(2), pat2), ...
                splitNamesWithPack, 'UniformOutput', true);
        else
            packNames = cellfun(@(x) x(1), splitNamesWithPack);
            msk2 = matches(packNames, pat1);
            % packNames = packNames(msk2);
        end
        %fprintf('msk2 sum: %d\n', sum(msk2));
        fns = cellfun(@(pcn) string(join(pcn, ".")), ...%pcn(1)+"."+pcn(2), ...
                splitNamesWithPack(msk2), 'UniformOutput', false);
    elseif ~isempty(opts.ClassNamePattern)
        %classNames = horzcat(cellfun(@(x) string(x(2)), splitNamesWithPack), ...
        %    splitNames(~msk));
        % fprintf('classNames: %s\n', formattedDisplayText(classNames));
        pat2 = regexpPattern(opts.ClassNamePattern, ...
            "IgnoreCase", opts.IgnoreCase, "Anchors", "text");
        msk2 = matches( cellfun(@(x) string(x(2)), splitNamesWithPack), ...
            pat2);
        classNames = cellfun(@(pcn) string(join(pcn, ".")), ...%pcn(1)+"."+pcn(2), ...
            splitNamesWithPack(msk2), 'UniformOutput', false);
        splitNamesWithoutPack = horzcat(string(splitNames(~msk)), ...
            cellfun(@(x) string(x.Name), meta.class.getAllClasses())');
        msk3 = matches(string(splitNamesWithoutPack), pat2);
        % fprintf('splitNamesWithoutPack: %s\n', formattedDisplayText(splitNamesWithoutPack));
        %fprintf('msk2 sum: %d\n', sum(msk2)+sum(msk3));
        fns = horzcat(classNames, splitNamesWithoutPack(msk3));
    end
    Fs = cellfun(@meta.class.fromName, fns, 'UniformOutput', false);
    fns = string(fns)';
    Fs = vertcat(Fs{:})';
end
end
% 
% 
%     [~,~,cns2] = inmem();
%     cns2 = setdiff(cns2, cns1, 'stable'); % cns2 = cns2';
%     cs2 = cellfun(@meta.class.fromName, cns2, 'UniformOutput', false);
%     [cs2, msk2] = filterclasses([cs2{:}], pat, opts.IgnoreCase, ...
%         opts.Abstract, opts.Hidden, opts.Sealed, opts.Enum, ...
%         opts.HandleCompat, opts.MinInferiors, opts.MinSuperiors, ...
%         true);
%     cns2 = cns2(msk2);
%     cs = [cs cs2];
%     cns = [ cns(:) ; cns2(:) ];
% end
% 
% 
% 
% 
% filterclasses(cs, pat, ignoreCase, abstr, hidd, seal, enum, handcomp, ...
%     mininf, minsup, recurse)
% 
% 
% [cns1b, ia] = setdiff(cns1a, icns0);
% cs1b = cs1a(ia);
% [cs,msk1b] = filterclasses(cs1b, opts.Abstract, opts.Hidden, ...
%     opts.Sealed, opts.Enum, opts.HandleCompat, ...
%     opts.MinInferiors, opts.MinSuperiors, opts.RecursiveSubSearch); 
%end


function [cs,msk] = filterclasses(cs, pat, ignoreCase, abstr, hidd, seal, enum, handcomp, ...
    mininf, minsup, recurse)%, requiredSups, requiredInfs)

cns = {cs.Name};
if ~isempty(pat)
    msk = matches(cns, regexpPattern(pat, "IgnoreCase", ignoreCase, ...
        "Anchors", "text"));
    cs = cs(msk); % cns = cns(msk);
end

% msk = true(size(cs));
cs0 = cs; % cns0 = cns;

filts = [abstr;hidd;seal;enum;handcomp];
filtMask = (strcmp(filts,"require"));
if(any(filtMask))
    filtNums = find(filtMask);
    for filtNum = filtNums
        switch filtNum
            case 1
                mask = [cs.Abstract];
            case 2
                mask = [cs.Hidden];
            case 3
                mask = [cs.Sealed];
            case 4
                mask = [cs.Enumeration];
            case 5
                mask = [cs.Enumeration];
        end
        cs = cs(mask);
        %msk = msk & mask;
    end
    filtNums = find(~filtMask);
else
    filtNums = [1 2 3 4 5];
end

if(~isempty(filtNums))
    for filtNum = filtNums
        switch filtNum
            case 1
                mask = [cs.Abstract];
            case 2
                mask = [cs.Hidden];
            case 3
                mask = [cs.Sealed];
            case 4
                mask = [cs.Enumeration];
            case 5
                mask = [cs.Enumeration];
        end
        if(filts(filtNum)~="exclude")
            mask = ~mask;
        end
        cs = cs(mask);
        %msk(mask) = msk & mask;
    end
end

if minsup
    supCounts = cellfun(@length, {cs1.SuperclassList}, ...
        'UniformOutput', true);
    mask = (supCounts >= minsup);
    cs = cs(mask);
    %msk = msk & mask;
end
if mininf
    infClasses = {cs1.InferiorClasses};
    infCounts = cellfun(@length, infClasses, ...
        'UniformOutput', true);
    if recurse
        infCounts = infCounts + ...
            cellfun(@(cname,ics) length(setdiff(...
            subclasses(cname, "SearchAllInMem", true).Name, ics)), ...
            {cs.Name}, infClasses, 'UniformOutput', true);
    end
    mask = (infCounts >= mininf);
    cs = cs(mask);
    %msk = msk & mask;
end
msk = ismember(cs0, cs);
% cns = cns(msk);
end

% disp(string({meta.package.fromName('matlab.mixin').ClassList.Name})')

function Cs = getPacksClasses(Ps)
Cs = cellfun(@(p) getPackClasses(p), Ps, 'UniformOutput', false);
Cs = vertcat(Cs{:});
%idxs(cellfun(@isempty,Cs)) == NaN;
end

function Cs = getPackClasses(packInfo)
Cs = packInfo.ClassList;
if isempty(Cs)
    Cs = [];
    %idx = [];
end
%end
end

% Cs = findclasses('[Ii]nput'); string({Cs.Name})'


% {'appdesigner.internal.application.observer.AppOpenedEventData'                    }
% {'appdesigner.internal.application.observer.SaveCompletedEventData'                }
% {'appdesigner.internal.service.CreateComponentsCompletedEventData'                 }
% {'appdesigner.internal.service.CallbackExecutionEventData'                         }
% {'appdesservices.internal.component.view.GuiEventData'                             }
% {'appdesservices.internal.interfaces.model.PropertiesMarkedDirtyEventData'         }
% {'event.EventData'                                                                 }
% {'images.roi.CircleMovingEventData'                                                }
% {'images.roi.CuboidMovingEventData'                                                }
% {'images.roi.EllipseMovingEventData'                                               }
% {'images.roi.RectangleMovingEventData'                                             }
% {'images.roi.ROIClickedEventData'                                                  }
% {'images.roi.ROIMovingEventData'                                                   }
% {'internal.hotplug.EventData'                                                      }
% {'internal.matlab.datatoolsservices.data.DataChangeEventData'                      }
% {'internal.matlab.datatoolsservices.data.ModelChangeEventData'                     }
% {'internal.matlab.variableeditor.ModelChangeEventData'                             }
% {'internal.matlab.variableeditor.CharacterWidthEventData'                          }
% {'internal.matlab.variableeditor.DataChangeEventData'                              }
% {'internal.matlab.variableeditor.DocumentChangeEventData'                          }
% {'internal.matlab.variableeditor.ManagerEventData'                                 }
% {'internal.matlab.variableeditor.MetaDataChangeEventData'                          }
% {'internal.matlab.variableeditor.OpenVariableEventData'                            }
% {'internal.matlab.variableeditor.PropertyChangeEventData'                          }
% {'internal.matlab.variableeditor.SelectionEventData'                               }
% {'internal.matlab.variableeditor.VariableEditEventData'                            }
% {'internal.matlab.variableeditor.VariableInteractionEventData'                     }
% {'matlab.graphics.controls.eventdata.ButtonPushedEventData'                        }
% {'matlab.graphics.controls.eventdata.ChildClickedEventData'                        }
% {'matlab.graphics.controls.eventdata.ProcessInteractionsEventData'                 }
% {'matlab.graphics.controls.eventdata.SelectionChangedEventData'                    }
% {'matlab.graphics.controls.eventdata.ValueChangedEventData'                        }
% {'matlab.graphics.controls.internal.InvisibleAxesEnterExitEventData'               }
% {'matlab.graphics.eventdata.ChildEventData'                                        }
% {'matlab.graphics.eventdata.ItemHitEventData'                                      }
% {'matlab.graphics.interaction.actions.LingerEventData'                             }
% {'matlab.graphics.interaction.graphicscontrol.ActionEventData'                     }
% {'matlab.graphics.interaction.graphicscontrol.EnterExitEventData'                  }
% {'matlab.graphics.interaction.graphicscontrol.ExitInteractionEventData'            }
% {'matlab.graphics.interaction.graphicscontrol.PreAndPostResponseEventData'         }
% {'matlab.graphics.interaction.graphicscontrol.InteractionObjects.DatatipsEventData'}
% {'matlab.graphics.interaction.uiaxes.MouseEventData'                               }
% {'matlab.graphics.interaction.uiaxes.ScrollEventData'                              }
% {'matlab.internal.asynchttpsave.AsyncHTTPContentEventData'                         }
% {'matlab.internal.editor.DataTipSyntheticEventData'                                }
% {'matlab.internal.editor.figure.FigureChangeEventData'                             }
% {'matlab.internal.editor.figure.FigureManagerEventData'                            }
% {'matlab.internal.editor.figure.ModelessInteractionEventData'                      }
% {'matlab.internal.parallel.ReferenceRequestedEventData'                            }
% {'matlab.ui.eventdata.internal.AbstractEventData'                                  }
% {'matlab.ui.eventdata.internal.UpdateErrorEventData'                               }
% {'matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData'              }
% {'matlab.ui.internal.databrowser.GenericEventData'                                 }
% {'matlab.ui.internal.databrowser.PreviewEventData'                                 }
% {'matlab.ui.internal.databrowser.qeContextMenuEventData'                           }
% {'matlab.ui.internal.desktop.FiguresDropTargetEventData'                           }
% {'parallel.internal.pool.PoolEventData'                                            }
% {'viewmodel.internal.interface.eventdata.GenericEventData'                         }
