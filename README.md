# ng2_form_components

___

## html-text-transform-component

An Angular2 component to edit HTML tags.

### Usage

A simple usage example:

    import 'package:angular2/bootstrap.dart';
    import 'package:angular2/angular2.dart';
    
    import 'package:ng2_form_components/ng2_form_components.dart';
    
    main() {
      bootstrap(AppComponent);
    }
    
    @Component(
        selector: 'my-app',
        template: '''<html-text-transform-component [buttons]="buttons" [model]="model" (transformation)="notifyUpdate(\$event)"></html-text-transform-component>''',
        changeDetection: ChangeDetectionStrategy.OnPush,
        directives: const [HTMLTextTransformComponent]
    )
    class AppComponent {
    
      final String model = 'Lorem&nbsp;ipsum dolor si amet...';
    
      final List<List<HTMLTextTransformation>> buttons = <List<HTMLTextTransformation>>[
        <HTMLTextTransformation>[
          new HTMLTextTransformation('b', 'B'),
          new HTMLTextTransformation('i', 'I'),
          new HTMLTextTransformation('u', 'U'),
          new HTMLTextTransformation('span', 'A', style: <String, String>{
            'float': 'right'
          })
        ],
        <HTMLTextTransformation>[
          new HTMLTextTransformation('li', 'LI')
        ]
      ];
    
      AppComponent();
    
      int updateCount = 0;
    
      void notifyUpdate(String newModel) {
        print('updated:(${++updateCount}): $newModel');
      }
    }

___