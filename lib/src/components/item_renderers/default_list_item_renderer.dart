library ng2_form_components.components.default_list_item_renderer;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:ng2_form_components/src/components/item_renderers/dynamic_list_item_renderer.dart' show DynamicListItemRenderer;

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
        <label [ngStyle]="{'margin-left': getHierarchyOffset(listItem), 'word-wrap': 'break-word', 'width': '100%'}">{{labelStream | async}}</label>
        <i *ngIf="isSelected(listItem)" class="fa fa-check" style="float:right"></i>
      </div>
    ''',
    changeDetection: ChangeDetectionStrategy.OnPush
)
class DefaultListItemRenderer<T extends Comparable<dynamic>> implements DynamicListItemRenderer, OnDestroy {

  //-----------------------------
  // input
  //-----------------------------

  final ListRendererService listRendererService;
  final ChangeDetectorRef changeDetector;
  final ListItem<Comparable<dynamic>> listItem;
  final IsSelectedHandler isSelected;
  final GetHierarchyOffsetHandler getHierarchyOffset;
  final LabelHandler labelHandler;

  StreamSubscription<List<ListRendererEvent<dynamic, Comparable<dynamic>>>> _eventSubscription;

  final Stream<String> labelStream;

  //-----------------------------
  // constructor
  //-----------------------------

  DefaultListItemRenderer(
    @Inject(ListRendererService) this.listRendererService,
    @Inject(ChangeDetectorRef) this.changeDetector,
    @Inject(ListItem) ListItem<T> listItem,
    @Inject(IsSelectedHandler) this.isSelected,
    @Inject(GetHierarchyOffsetHandler) this.getHierarchyOffset,
    @Inject(LabelHandler) LabelHandler labelHandler,
    @Inject(Element) Element elementRef) :
      this.listItem = listItem,
      this.labelHandler = labelHandler,
      this.labelStream = (_resolveLabel(labelHandler(listItem.data)))
  {
    _initStreams();
  }

  @override void ngOnDestroy() {
    _eventSubscription?.cancel();
  }

  void _initStreams() {
    _eventSubscription = listRendererService.responders$
      .where((List<ListRendererEvent<dynamic, Comparable<dynamic>>> events) => events.firstWhere((ListRendererEvent<dynamic, Comparable<dynamic>> event) => event.type == 'selectionChanged', orElse: () => null) != null)
      .listen((_) => changeDetector.markForCheck());
  }

  static Stream<String> _resolveLabel(dynamic label) {
    if (label is String) return new Stream<String>.fromIterable(<String>[label]);

    return label as Stream<String>;
  }

  void triggerSelection() => listRendererService.triggerSelection(listItem);

}