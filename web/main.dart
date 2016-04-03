import 'dart:async';
import 'dart:math';

import 'package:angular2/bootstrap.dart';
import 'package:angular2/angular2.dart';
import 'package:ng2_state/ng2_state.dart';

import 'package:ng2_form_components/ng2_form_components.dart';

import 'package:faker/faker.dart';

import 'person_list_item_renderer.dart';
import 'person.dart' as domain;

import 'orm_init.dart' show ormInitialize;

void main() {
  ormInitialize();

  bootstrap(AppComponent);
}

@Component(
    selector: 'my-app',
    templateUrl: 'app_component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: const [StateService],
    directives: const [State, TextInput, DropDown, AutoComplete, Hierarchy, HTMLTextTransformComponent]
)
class AppComponent {

  final ChangeDetectorRef changeDetector;
  final StateService stateService;
  final Random random = new Random();
  final TextInputAction notifyInputAction = (String inputValue) => print(inputValue);

  Type listItemRenderer = DefaultListItemRenderer;
  Type personListItemRenderer = PersonListItemRenderer;

  LabelHandler labelHandler = (String value) => value;
  LabelHandler personLabelHandler = (domain.Person value) => value.name;
  LabelHandler hierarchyLabelHandler = (HierarchyLevel value) => value.label;

  List<ListItem<domain.Person>> fakeData;

  List<ListItem<String>> dataProviderA, dataProviderB;
  List<ListItem<HierarchyLevel>> dataProviderC = <ListItem<HierarchyLevel>>[];
  List<ListItem<String>> selectedItem;
  List<ListItem<String>> selectedItems;
  List<ListItem<domain.Person>> mockResultDataProviderA, mockResultDataProviderB;

  StateRecordingSession recordingSession;
  bool isReplaying = false;

  ResolveChildrenHandler resolveChildrenHandler = (int level, ListItem listItem) {
    final ListItem<HierarchyLevel> cast = listItem as ListItem<HierarchyLevel>;
    List<ListItem<HierarchyLevel>> result;

    if (cast.data.children != null) {
      result = (cast.data.children.map((HierarchyLevel item) => new ListItem<HierarchyLevel>()
        ..data = item
        ..container = ''
        ..selectable = true)).toList(growable: false);
    } else result = <ListItem<HierarchyLevel>>[];

    return result;
  };

  final String model = 'Dart and Angular2 plus some reactive awesome sauce';

  final List<List<HTMLTextTransformation>> buttons = <List<HTMLTextTransformation>>[
    <HTMLTextTransformation>[
      new HTMLTextTransformation('b', '<i class="fa fa-bold"></i>'),
      new HTMLTextTransformation('i', '<i class="fa fa-italic"></i>'),
      new HTMLTextTransformation('u', '<i class="fa fa-underline"></i>'),
      new HTMLTextTransformation('li', '<i class="fa fa-list"></i>'),
      new HTMLTextTransformation('font', '<i class="fa fa-paint-brush"></i>', style: <String, String>{'color': 'red'})
    ]
  ];

  AppComponent(@Inject(ChangeDetectorRef) this.changeDetector, @Inject(StateService) this.stateService) {
    stateService.stateName = 'ng2-form-components';
    fakeData = _generateRandomServiceData().toList(growable: false);

    stateService.init();

    ListItem<String> rootA = new ListItem<String>()
      ..data = 'apples'
      ..container = ''
      ..selectable = false;
    ListItem<String> rootB = new ListItem<String>()
      ..data = 'oranges'
      ..container = ''
      ..selectable = false;
    ListItem<String> rootC = new ListItem<String>()
      ..data = 'lemons'
      ..container = ''
      ..selectable = false;

    ListItem<String> level1A = new ListItem<String>()
      ..data = 'bananas'
      ..container = ''
      ..selectable = true;
    ListItem<String> level1B = new ListItem<String>()
      ..data = 'grapes'
      ..parent = rootA
      ..container = ''
      ..selectable = true;

    ListItem<String> level2A = new ListItem<String>()
      ..data = 'pears'
      ..parent = level1A
      ..container = ''
      ..selectable = true;
    ListItem<String> level2B = new ListItem<String>()
      ..data = 'cherries'
      ..parent = level1A
      ..container = ''
      ..selectable = true;

    dataProviderA = new List<ListItem<String>>.unmodifiable(<ListItem<String>>[
      rootA,
      level1A,
      level2A, level2B,
      level1B,
      rootB, rootC
    ]);

    dataProviderB = new List<ListItem<String>>.unmodifiable(<ListItem<String>>[
      rootA,
      level1A,
      level2A, level2B,
      level1B,
      rootB, rootC
    ]);

    ListItem<HierarchyLevel> h_rootA = new ListItem<HierarchyLevel>()
      ..data = (new HierarchyLevel()
        ..label = 'Question 1'
        ..children = <HierarchyLevel>[
          new HierarchyLevel()
            ..label = 'Answer 1',
          new HierarchyLevel()
            ..label = 'Answer 2'
            ..children = <HierarchyLevel>[
              new HierarchyLevel()
                ..label = 'Answer 1',
              new HierarchyLevel()
                ..label = 'Answer 2'
                ..children = <HierarchyLevel>[
                  new HierarchyLevel()
                    ..label = 'Answer 1',
                  new HierarchyLevel()
                    ..label = 'Answer 2',
                  new HierarchyLevel()
                    ..label = 'Answer 3'
                ]
            ],
          new HierarchyLevel()
            ..label = 'Answer 3'
        ])
      ..container = ''
      ..selectable = true;

    ListItem<HierarchyLevel> h_rootB = new ListItem<HierarchyLevel>()
      ..data = (new HierarchyLevel()
        ..label = 'Question 2'
        ..children = <HierarchyLevel>[
          new HierarchyLevel()
            ..label = 'Answer 1',
          new HierarchyLevel()
            ..label = 'Answer 2',
          new HierarchyLevel()
            ..label = 'Answer 3'
        ])
      ..container = ''
      ..selectable = true;

    dataProviderC = new List<ListItem<HierarchyLevel>>.unmodifiable(<ListItem<HierarchyLevel>>[
      h_rootA,
      h_rootB
    ]);

    selectedItem = new List<ListItem<String>>.unmodifiable(<ListItem<String>>[
      level2A
    ]);

    selectedItems = new List<ListItem<String>>.unmodifiable(<ListItem<String>>[
      level2A, level2B
    ]);
  }

  void startRecording() {
    if (recordingSession == null) recordingSession = stateService.startRecordingSession();
  }

  void replayRecording() {
    if (recordingSession != null) {
      isReplaying = true;

      stateService.replayRecordingSession(recordingSession).whenComplete(() => isReplaying = false);
    }

    recordingSession = null;
  }

  String _oldAutoFillTextA, _oldAutoFillTextB;

  void triggerMockServiceA(String autoFillText) {
    if (_oldAutoFillTextA == autoFillText) return;

    _oldAutoFillTextA = autoFillText;

    new Timer(new Duration(milliseconds: random.nextInt(2000)), () {
      mockResultDataProviderA = fakeData
        .where((ListItem<domain.Person> listItem) => listItem.data.name.contains(autoFillText))
        .take(50)
        .toList(growable: false);

      changeDetector.markForCheck();
    });
  }

  void triggerMockServiceB(String autoFillText) {
    if (_oldAutoFillTextB == autoFillText) return;

    _oldAutoFillTextB = autoFillText;

    new Timer(new Duration(milliseconds: random.nextInt(2000)), () {
      mockResultDataProviderB = fakeData
          .where((ListItem<domain.Person> listItem) => listItem.data.name.contains(autoFillText))
          .take(50)
          .toList(growable: false);

      changeDetector.markForCheck();
    });
  }

  Iterable<ListItem<domain.Person>> _generateRandomServiceData() sync* {
    for (int i=0; i<5000; i++) yield new ListItem<domain.Person>()
      ..data = (new domain.Person()
        ..name = '${faker.person.firstName()} ${faker.person.lastName()}'
        ..image = 'images/img_${random.nextInt(40) + 1}.png')
      ..container = ''
      ..selectable = true;
  }

  void notifyItemRendererEvent(ItemRendererEvent event) => print(event.type);

  String listItemsAToString(List<ListItem<String>> items) => items.map((ListItem<String> item) => labelHandler(item.data)).join(', ');

  String listItemsBToString(List<ListItem<domain.Person>> items) => items.map((ListItem<domain.Person> item) => personLabelHandler(item.data)).join(', ');

  void handleRange(bool hasRange) {
    print(hasRange);
  }
}