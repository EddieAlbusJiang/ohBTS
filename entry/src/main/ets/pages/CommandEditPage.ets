import { DisplayMode } from '../common/Types';
import { CommandManager } from '../common/CommandManager';
import { SettingsManager } from '../common/SettingsManager';

@Component
export struct CommandEditPage {
  @State commandName: string = '';
  @State commandContent: string = '';
  @State displayMode: DisplayMode = DisplayMode.ASCII;
  @State isEditMode: boolean = false;
  @State commandId: string = '';
  @State repeatCountStr: string = '1';
  @Consume('pathStack') pathStack: NavPathStack;
  
  private commandManager: CommandManager = CommandManager.getInstance();
  private settingsManager: SettingsManager = SettingsManager.getInstance();
  
  aboutToAppear() {
    this.displayMode = this.settingsManager.displayMode;
    
    const editId = this.commandManager.getEditingCommandId();
    if (editId) {
      const command = this.commandManager.getCommand(editId);
      if (command) {
        this.isEditMode = true;
        this.commandId = command.id;
        this.commandName = command.name;
        this.commandContent = command.content;
        this.displayMode = command.displayMode;
        this.repeatCountStr = command.repeatCount && command.repeatCount > 0
          ? command.repeatCount.toString() : '1';
      }
      this.commandManager.clearEditingCommandId();
    }
  }
  
  build() {
    NavDestination() {
      Column() {
        Row() {
          Button() {
            Text('取消')
              .fontSize(16)
              .fontColor('#007DFF')
          }
          .width(60)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.pathStack.pop();
          })
          
          Text(this.isEditMode ? '编辑指令' : '新建指令')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          
          Button() {
            Text('保存')
              .fontSize(16)
              .fontColor('#007DFF')
          }
          .width(60)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.saveCommand();
          })
        }
        .width('100%')
        .height(56)
        .padding({ left: 8, right: 8 })
        .backgroundColor(Color.White)
        
        // Divider()
        
        Scroll() {
          Column() {
            Column() {
              Text('指令名称')
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .margin({ bottom: 8 })
              
              TextInput({ placeholder: '请输入指令名称', text: this.commandName })
                .width('100%')
                .height(44)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .onChange((value: string) => {
                  this.commandName = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            
            Divider()
            
            Row() {
              Text(`当前模式: ${this.displayMode}`)
                .fontSize(14)
                .fontColor('#666666')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            
            Divider()
            
            Column() {
              Text('指令内容')
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .margin({ bottom: 8 })
              
              TextArea({ placeholder: this.getContentPlaceholder(), text: this.commandContent })
                .width('100%')
                .height(150)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .onChange((value: string) => {
                  this.commandContent = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            
            Divider()
            
            Column() {
              Text('重复发送次数')
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .margin({ bottom: 8 })
              
              TextInput({ placeholder: '1', text: this.repeatCountStr })
                .width('100%')
                .height(44)
                .type(InputType.Number)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .onChange((value: string) => {
                  this.repeatCountStr = value;
                })
              
              Text('未设置则默认发送1次')
                .fontSize(12)
                .fontColor('#BBBBBB')
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .alignItems(HorizontalAlign.Start)
          }
        }
        .layoutWeight(1)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Start)
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }
  
  private getContentPlaceholder(): string {
    if (this.displayMode === DisplayMode.HEX) {
      return '请输入十六进制数据，如: 01 02 03 FF';
    } else {
      return '请输入ASCII文本';
    }
  }
  
  private async saveCommand() {
    if (!this.commandName.trim()) {
      AlertDialog.show({
        title: '提示',
        message: '请输入指令名称'
      });
      return;
    }
    
    if (!this.commandContent.trim()) {
      AlertDialog.show({
        title: '提示',
        message: '请输入指令内容'
      });
      return;
    }
    
    let repeatCount = parseInt(this.repeatCountStr);
    if (isNaN(repeatCount) || repeatCount < 1) {
      repeatCount = 1;
    }
    
    if (this.isEditMode) {
      await this.commandManager.updateCommand(
        this.commandId,
        this.commandName,
        this.commandContent,
        this.displayMode,
        repeatCount
      );
    } else {
      await this.commandManager.addCommand(
        this.commandName,
        this.commandContent,
        this.displayMode,
        repeatCount
      );
    }
    
    this.pathStack.pop();
  }
}

@Builder
export function buildCommandEditPage() {
  CommandEditPage()
}
