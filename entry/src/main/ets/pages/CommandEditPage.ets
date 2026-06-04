import { QuickCommand, DisplayMode } from '../common/Types';
import { CommandManager } from '../common/CommandManager';
import { SettingsManager } from '../common/SettingsManager';
import router from '@ohos.router';

/**
 * 指令编辑页面
 */
@Entry
@Component
struct CommandEditPage {
  @State commandName: string = '';
  @State commandContent: string = '';
  @State displayMode: DisplayMode = DisplayMode.ASCII;
  @State isEditMode: boolean = false;
  @State commandId: string = '';
  
  private commandManager: CommandManager = CommandManager.getInstance();
  private settingsManager: SettingsManager = SettingsManager.getInstance();
  
  aboutToAppear() {
    // 获取当前显示模式
    this.displayMode = this.settingsManager.displayMode;
    
    // 检查是否为编辑模式（通过路由参数传递）
    // 注意：这里需要在实际使用时通过其他方式传递参数
  }
  
  build() {
    Column() {
      // 标题栏
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
          router.back();
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
      
      Divider()
      
      // 编辑区域
      Column() {
        // 指令名称
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
        
        // 显示模式提示
        Row() {
          Text(`当前模式: ${this.displayMode}`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        
        Divider()
        
        // 指令内容
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
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 获取内容提示
   */
  private getContentPlaceholder(): string {
    if (this.displayMode === DisplayMode.HEX) {
      return '请输入十六进制数据，如: 01 02 03 FF';
    } else {
      return '请输入ASCII文本';
    }
  }
  
  /**
   * 保存指令
   */
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
    
    if (this.isEditMode) {
      await this.commandManager.updateCommand(
        this.commandId,
        this.commandName,
        this.commandContent,
        this.displayMode
      );
    } else {
      await this.commandManager.addCommand(
        this.commandName,
        this.commandContent,
        this.displayMode
      );
    }
    
    router.back();
  }
}
