import { DisplayMode, QuickCommand } from '../common/Types';
import { SettingsManager } from '../common/SettingsManager';
import { CommandManager } from '../common/CommandManager';
import common from '@ohos.app.ability.common';
import { picker, fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import util from '@ohos.util';

@Component
struct SettingsPage {
  @State displayMode: DisplayMode = DisplayMode.ASCII;
  @State commandCount: number = 0;
  @State autoResendInterval: number = 50;
  @State isEditingInterval: boolean = false;
  @State intervalInputStr: string = '50';
  @Consume('pathStack') pathStack: NavPathStack;
  
  private settingsManager: SettingsManager = SettingsManager.getInstance();
  private commandManager: CommandManager = CommandManager.getInstance();
  
  aboutToAppear() {
    this.displayMode = this.settingsManager.displayMode;
    this.autoResendInterval = this.settingsManager.autoResendInterval;
    this.commandCount = this.commandManager.commands.length;
    
    this.commandManager.setOnCommandsChange(() => {
      this.commandCount = this.commandManager.commands.length;
    });
    
    this.settingsManager.setOnSettingsChange(() => {
      this.displayMode = this.settingsManager.displayMode;
      this.autoResendInterval = this.settingsManager.autoResendInterval;
    });
  }
  
  build() {
    NavDestination() {
      Column() {
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
            this.pathStack.pop();
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
        
        Column() {
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
          
          Text('选择串口数据的显示和编辑模式')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .padding({ left: 16, top: 8, bottom: 16 })
        }
        .margin({ top: 16 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        
        Column() {
          Row() {
            Text('自动重发间隔')
              .fontSize(16)
              .layoutWeight(1)
            
            if (this.isEditingInterval) {
              TextInput({ placeholder: '50', text: this.intervalInputStr })
                .width(80)
                .height(36)
                .type(InputType.Number)
                .fontSize(14)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .onChange((value: string) => {
                  this.intervalInputStr = value;
                })
              
              Button('确定')
                .width(48)
                .height(36)
                .fontSize(13)
                .backgroundColor('#007DFF')
                .fontColor(Color.White)
                .margin({ left: 8 })
                .onClick(() => {
                  this.confirmInterval();
                })
            } else {
              Row() {
                Text(`${this.autoResendInterval} ms`)
                  .fontSize(14)
                  .fontColor('#666666')
                
                Text('>')
                  .fontSize(16)
                  .fontColor('#CCCCCC')
                  .margin({ left: 8 })
              }
            }
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .backgroundColor(Color.White)
          .onClick(() => {
            if (!this.isEditingInterval) {
              this.isEditingInterval = true;
              this.intervalInputStr = this.autoResendInterval.toString();
            }
          })
          
          Divider()
            .margin({ left: 16 })
          
          Text('快捷命令重复发送时的时间间隔')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .padding({ left: 16, top: 8, bottom: 16 })
        }
        .margin({ top: 16 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        
        Column() {
          Row() {
            Text('快捷命令管理')
              .fontSize(16)
              .layoutWeight(1)
            
            Text(`共 ${this.commandCount} 条`)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          
          Divider()
            .margin({ left: 16 })
          
          Row() {
            Text('导出命令')
              .fontSize(16)
              .layoutWeight(1)
            
            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.exportCommands();
          })
          
          Divider()
            .margin({ left: 16 })
          
          Row() {
            Text('导入命令')
              .fontSize(16)
              .layoutWeight(1)
            
            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.importCommands();
          })
          
          Divider()
            .margin({ left: 16 })
          
          Row() {
            Text('清空所有命令')
              .fontSize(16)
              .fontColor('#FF4444')
              .layoutWeight(1)
            
            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.clearCommands();
          })
        }
        .margin({ top: 16 })
        .backgroundColor(Color.White)
        .borderRadius(8)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }
  
  private showModeSelector() {
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
  
  private confirmInterval() {
    let value = parseInt(this.intervalInputStr);
    if (isNaN(value) || value < 0) {
      value = 50;
    }
    this.autoResendInterval = value;
    this.settingsManager.autoResendInterval = value;
    this.isEditingInterval = false;
  }
  
  private async exportCommands() {
    try {
      const commands = this.commandManager.commands;
      if (commands.length === 0) {
        AlertDialog.show({
          title: '提示',
          message: '没有可导出的命令',
          primaryButton: { value: '确定', action: () => {} }
        });
        return;
      }
      
      const context = getContext(this) as common.UIAbilityContext;
      
      const fileName = `commands_${Date.now()}.json`;
      const sandboxPath = `${context.filesDir}/${fileName}`;
      const file = fs.openSync(sandboxPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      const data = JSON.stringify(commands, null, 2);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);
      
      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.newFileNames = [fileName];
      documentSaveOptions.fileSuffixChoices = ['.json'];
      
      const documentViewPicker = new picker.DocumentViewPicker(context);
      documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
        if (documentSaveResult && documentSaveResult.length > 0) {
          const destUri = documentSaveResult[0];
          const sandboxFile = fs.openSync(sandboxPath, fs.OpenMode.READ_ONLY);
          const destFile = fs.openSync(destUri, fs.OpenMode.WRITE_ONLY);
          fs.copyFileSync(sandboxFile.fd, destFile.fd);
          fs.closeSync(sandboxFile);
          fs.closeSync(destFile);
          
          AlertDialog.show({
            title: '导出成功',
            message: `已导出 ${commands.length} 条命令`,
            primaryButton: { value: '确定', action: () => {} }
          });
        }
      }).catch((err: BusinessError) => {
        console.error('DocumentViewPicker.save failed:', err);
        AlertDialog.show({
          title: '导出取消',
          message: '用户取消了导出操作',
          primaryButton: { value: '确定', action: () => {} }
        });
      });
    } catch (error) {
      console.error('Export commands failed:', error);
      AlertDialog.show({
        title: '导出失败',
        message: '导出命令时发生错误',
        primaryButton: { value: '确定', action: () => {} }
      });
    }
  }
  
  private async importCommands() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      documentSelectOptions.fileSuffixFilters = ['.json'];
      
      const documentViewPicker = new picker.DocumentViewPicker(context);
      documentViewPicker.select(documentSelectOptions).then(async (documentSelectResult: Array<string>) => {
        if (documentSelectResult && documentSelectResult.length > 0) {
          const srcUri = documentSelectResult[0];
          
          const file = fs.openSync(srcUri, fs.OpenMode.READ_ONLY);
          const stat = fs.statSync(srcUri);
          const buffer = new ArrayBuffer(stat.size);
          fs.readSync(file.fd, buffer);
          fs.closeSync(file);
          
          const decoder = new util.TextDecoder('utf-8');
          const data = decoder.decodeToString(new Uint8Array(buffer));
          const commands = JSON.parse(data) as QuickCommand[];
          
          AlertDialog.show({
            title: '确认导入',
            message: `即将导入 ${commands.length} 条命令，现有命令将被保留。是否继续？`,
            primaryButton: {
              value: '取消',
              action: () => {}
            },
            secondaryButton: {
              value: '导入',
              action: async () => {
                for (const cmd of commands) {
                  const rc = cmd.repeatCount && cmd.repeatCount > 0 ? cmd.repeatCount : 1;
                  await this.commandManager.addCommand(cmd.name, cmd.content, cmd.displayMode, rc);
                }
                AlertDialog.show({
                  title: '导入成功',
                  message: `已导入 ${commands.length} 条命令`,
                  primaryButton: { value: '确定', action: () => {} }
                });
              }
            }
          });
        }
      }).catch((err: BusinessError) => {
        console.error('DocumentViewPicker.select failed:', err);
        AlertDialog.show({
          title: '导入取消',
          message: '用户取消了导入操作',
          primaryButton: { value: '确定', action: () => {} }
        });
      });
    } catch (error) {
      console.error('Import commands failed:', error);
      AlertDialog.show({
        title: '导入失败',
        message: '导入命令时发生错误',
        primaryButton: { value: '确定', action: () => {} }
      });
    }
  }
  
  private async clearCommands() {
    if (this.commandCount === 0) {
      AlertDialog.show({
        title: '提示',
        message: '没有可清空的命令',
        primaryButton: { value: '确定', action: () => {} }
      });
      return;
    }
    
    AlertDialog.show({
      title: '确认清空',
      message: `确定要清空所有 ${this.commandCount} 条命令吗？此操作不可撤销。`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '清空',
        action: async () => {
          const commands = [...this.commandManager.commands];
          for (const cmd of commands) {
            await this.commandManager.deleteCommand(cmd.id);
          }
          AlertDialog.show({
            title: '清空成功',
            message: '已清空所有命令',
            primaryButton: { value: '确定', action: () => {} }
          });
        }
      }
    });
  }
}

@Builder
export function buildSettingsPage() {
  SettingsPage()
}
