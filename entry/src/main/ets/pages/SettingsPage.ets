import { DisplayMode } from '../common/Types';
import { SettingsManager } from '../common/SettingsManager';
import router from '@ohos.router';

/**
 * 设置页面
 */
@Entry
@Component
struct SettingsPage {
  @State displayMode: DisplayMode = DisplayMode.ASCII;
  private settingsManager: SettingsManager = SettingsManager.getInstance();
  
  aboutToAppear() {
    this.displayMode = this.settingsManager.displayMode;
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('返回')
            .fontSize(16)
            .fontColor('#007DFF')
        }
        .width(60)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })
        
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Blank()
          .width(60)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      
      Divider()
      
      // 设置列表
      Column() {
        // 串口呈现模式
        Row() {
          Text('串口呈现模式')
            .fontSize(16)
            .layoutWeight(1)
          
          Row() {
            Text(this.displayMode)
              .fontSize(14)
              .fontColor('#666666')
            
            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
              .margin({ left: 8 })
          }
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Color.White)
        .onClick(() => {
          this.showModeSelector();
        })
        
        Divider()
          .margin({ left: 16 })
        
        // 模式说明
        Text('选择串口数据的显示和编辑模式')
          .fontSize(12)
          .fontColor('#999999')
          .width('100%')
          .padding({ left: 16, top: 8, bottom: 8 })
      }
      .margin({ top: 16 })
      .backgroundColor(Color.White)
      .borderRadius(8)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 显示模式选择器
   */
  private showModeSelector() {
    // 使用AlertDialog选择模式
    AlertDialog.show({
      title: '串口呈现模式',
      message: '请选择串口数据的显示和编辑模式',
      primaryButton: {
        value: 'ASCII',
        action: () => {
          this.displayMode = DisplayMode.ASCII;
          this.settingsManager.displayMode = DisplayMode.ASCII;
        }
      },
      secondaryButton: {
        value: 'Hex',
        action: () => {
          this.displayMode = DisplayMode.HEX;
          this.settingsManager.displayMode = DisplayMode.HEX;
        }
      }
    });
  }
}
