import 'dart:async';

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/item_renderers/dynamic_list_item_renderer.dart'
    show DynamicListItemRenderer;

import 'package:ng2_form_components/src/components/internal/form_component.dart';
import 'package:ng2_form_components/src/components/internal/list_item_renderer.dart';
import 'package:ng2_form_components/src/components/list_item.g.dart';

import 'package:ng2_form_components/src/infrastructure/list_renderer_service.dart';

@Component(
    selector: 'default-list-item-renderer',
    directives: const <dynamic>[coreDirectives],
    pipes: const <dynamic>[commonPipes],
    template: '''
      <div class="instance" (click)="triggerSelection()" style="padding:5px">
        <label [ngStyle]="{'margin-left': getHierarchyOffset(listItem), 'word-wrap': 'break-word', 'width': '100%'}">{{labelHandler(listItem.data)}}</label>
        <i *ngIf="isSelected(listItem)" class="fa fa-check" style="float:right"></i>
      </div>
    ''',
    changeDetection: ChangeDetectionStrategy.OnPush)
class DefaultListItemRenderer<T extends Comparable<dynamic>>
    implements DynamicListItemRenderer, OnDestroy {
  //-----------------------------
  // input
  //-----------------------------

  final ListRendererService listRendererService;
  final ChangeDetectorRef changeDetector;
  final ListItem<Comparable<dynamic>> listItem;
  final IsSelectedHandler isSelected;
  final GetHierarchyOffsetHandler getHierarchyOffset;
  final LabelHandler<T> labelHandler;

  StreamSubscription<List<ListRendererEvent<dynamic, Comparable<dynamic>>>>
      _eventSubscription;

  //-----------------------------
  // constructor
  //-----------------------------

  DefaultListItemRenderer(
      @Inject(ListRendererService) this.listRendererService,
      @Inject(ChangeDetectorRef) this.changeDetector,
      @Inject(ListItem) this.listItem,
      @Inject(IsSelectedHandler) this.isSelected,
      @Inject(GetHierarchyOffsetHandler) this.getHierarchyOffset,
      @Inject(LabelHandler) this.labelHandler) {
    _initStreams();
  }

  @override
  void ngOnDestroy() {
    _eventSubscription?.cancel();
  }

  void _initStreams() {
    _eventSubscription = listRendererService.responders$
        .where((List<ListRendererEvent<dynamic, Comparable<dynamic>>> events) =>
            events.firstWhere(
                (ListRendererEvent<dynamic, Comparable<dynamic>> event) =>
                    event.type == 'selectionChanged',
                orElse: () => null) !=
            null)
        .listen((_) => changeDetector.markForCheck());
  }

  void triggerSelection() {
    listRendererService.triggerSelection(listItem);
  }
}
