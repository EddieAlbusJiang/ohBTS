import { QuickCommand, SerialData, DisplayMode } from '../common/Types';
import { BluetoothManager } from '../common/BluetoothManager';
import { CommandManager } from '../common/CommandManager';
import { SettingsManager } from '../common/SettingsManager';

/**
 * 快捷命令页面
 */
@Component
export struct QuickCommandPage {
  @State commands: QuickCommand[] = [];
  @State serialDataHistory: SerialData[] = [];
  @State displayMode: DisplayMode = DisplayMode.ASCII;
  @Consume('pathStack') pathStack: NavPathStack;
  
  private bluetoothManager: BluetoothManager = BluetoothManager.getInstance();
  private commandManager: CommandManager = CommandManager.getInstance();
  private settingsManager: SettingsManager = SettingsManager.getInstance();
  private scroller: Scroller = new Scroller(); // 滚动控制器
  
  aboutToAppear() {
    // 加载指令
    this.commands = this.commandManager.commands.map(cmd => {
      let newCmd: QuickCommand = {
        id: cmd.id, name: cmd.name, content: cmd.content,
        displayMode: cmd.displayMode,
        repeatCount: cmd.repeatCount ? cmd.repeatCount : 1
      };
      return newCmd;
    });
    this.displayMode = this.settingsManager.displayMode;
    
    // 设置回调
    this.bluetoothManager.setOnDataReceived((data: SerialData) => {
      this.serialDataHistory = [...this.bluetoothManager.serialDataHistory];
      // 自动滚动到底部
      if (this.serialDataHistory.length > 0) {
        setTimeout(() => {
          this.scroller.scrollToIndex(this.serialDataHistory.length - 1);
        }, 50);
      }
    });
    
    this.commandManager.setOnCommandsChange(() => {
      this.commands = this.commandManager.commands.map(cmd => {
        let newCmd: QuickCommand = {
          id: cmd.id, name: cmd.name, content: cmd.content,
          displayMode: cmd.displayMode,
          repeatCount: cmd.repeatCount ? cmd.repeatCount : 1
        };
        return newCmd;
      });
    });
    
    // 监听设置变化
    this.settingsManager.setOnSettingsChange(() => {
      this.displayMode = this.settingsManager.displayMode;
    });
    
    // 加载历史数据
    this.serialDataHistory = this.bluetoothManager.serialDataHistory;
  }
  
  /**
   * 页面每次显示时刷新命令列表
   */
  onPageShow() {
    // 刷新命令列表，确保编辑后的内容能够更新
    this.commands = this.commandManager.commands.map(cmd => {
      let newCmd: QuickCommand = {
        id: cmd.id, name: cmd.name, content: cmd.content,
        displayMode: cmd.displayMode,
        repeatCount: cmd.repeatCount ? cmd.repeatCount : 1
      };
      return newCmd;
    });
  }

  
  build() {
    Column() {
      // 顶部按钮栏
      Row() {
        Button() {
          Text('清空')
            .fontSize(14)
            .fontColor('#007DFF')
        }
        .width(60)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.clearHistory();
        })
        
        Blank()
          .layoutWeight(1)
        
        Button() {
          Text('+')
            .fontSize(20)
            .fontColor('#FFFFFF')
        }
        .width(32)
        .height(32)
        .backgroundColor('#007DFF')
        .borderRadius(16)
        .onClick(() => {
          this.commandManager.setEditingCommandId('');
          this.pathStack.pushPathByName('CommandEditPage', null);
        })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      
      // 串口数据显示区域
      Column() {
        List({ scroller: this.scroller }) {
          ForEach(this.serialDataHistory, (data: SerialData, index: number) => {
            ListItem() {
              this.SerialDataItem(data)
            }
          }, (data: SerialData, index: number) => index.toString())
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(6)
      .backgroundColor('#1E1E1E')
      .padding(8)
      
      Divider()
      
      // 快捷指令列表
      Column() {
        if (this.commands.length === 0) {
          Text('暂无快捷指令')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 20 })
        } else {
          List() {
            ForEach(this.commands, (command: QuickCommand) => {
              ListItem() {
                this.CommandItem(command)
              }
            }, (command: QuickCommand) => `${command.id}_${command.name}_${command.content}_${command.displayMode}_${command.repeatCount}`)
          }
          .width('100%')
        }
      }
      .width('100%')
      .height(200)
      .backgroundColor(Color.White)
      .layoutWeight(4)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 串口数据项
   */
  @Builder
  SerialDataItem(data: SerialData) {
    Row() {
      Text(data.isSend ? 'TX' : 'RX')
        .fontSize(12)
        .fontColor(data.isSend ? '#00FF00' : '#00FFFF')
        .width(25).alignSelf(ItemAlign.Start)

      Text(this.formatTimestamp(data.timestamp))
        .fontSize(12)
        .fontColor('#888888')
        .width(90).alignSelf(ItemAlign.Start)

      Text(this.formatData(data))
        .fontSize(12)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
  
  /**
   * 快捷指令项
   */
  @Builder
  CommandItem(command: QuickCommand) {
    Row() {
      Text(command.name)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
      
      Button('发')
        .width(48)
        .height(32)
        .fontSize(14)
        .backgroundColor('#007DFF')
        .onClick(() => {
          this.sendCommand(command);
        })
      
      Button('改')
        .width(48)
        .height(32)
        .fontSize(14)
        .backgroundColor('#FF9900')
        .margin({ left: 5 })
        .onClick(() => {
          this.commandManager.setEditingCommandId(command.id);
          this.pathStack.pushPathByName('CommandEditPage', null);
        })
      
      Button('删')
        .width(48)
        .height(32)
        .fontSize(14)
        .backgroundColor('#FF4444')
        .margin({ left: 5 })
        .onClick(() => {
          this.deleteCommand(command.id);
        })
    }
    .width('100%')
    .padding(8)
    .backgroundColor(Color.White)
  }
  
  /**
   * 格式化时间戳
   */
  private formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');
    const millis = date.getMilliseconds().toString().padStart(4, '0');
    return `${hours}:${minutes}:${seconds}.${millis}`;
  }
  
  /**
   * 格式化数据
   */
  private formatData(data: SerialData): string {
    if (this.displayMode === DisplayMode.HEX && data.displayMode === DisplayMode.ASCII) {
      // ASCII转Hex显示
      return this.asciiToHex(data.content);
    } else if (this.displayMode === DisplayMode.ASCII && data.displayMode === DisplayMode.HEX) {
      // Hex转ASCII显示
      return this.hexToAscii(data.content);
    }
    return data.content;
  }
  
  /**
   * ASCII转Hex
   */
  private asciiToHex(str: string): string {
    let hex = '';
    for (let i = 0; i < str.length; i++) {
      hex += str.charCodeAt(i).toString(16).padStart(2, '0').toUpperCase() + ' ';
    }
    return hex.trim();
  }
  
  /**
   * Hex转ASCII
   */
  private hexToAscii(hex: string): string {
    const hexArray = hex.replace(/\s/g, '').match(/.{1,2}/g) || [];
    let str = '';
    for (const byte of hexArray) {
      str += String.fromCharCode(parseInt(byte, 16));
    }
    return str;
  }
  
  /**
   * 发送指令
   */
  private async sendCommand(command: QuickCommand) {
    const isHex = command.displayMode === DisplayMode.HEX;
    const count = command.repeatCount && command.repeatCount > 0 ? command.repeatCount : 1;
    const interval = this.settingsManager.autoResendInterval;
    
    for (let i = 0; i < count; i++) {
      if (i > 0) {
        await this.delay(interval);
      }
      await this.bluetoothManager.sendData(command.content, isHex);
      this.serialDataHistory = [...this.bluetoothManager.serialDataHistory];
    }
    
    if (this.serialDataHistory.length > 0) {
      setTimeout(() => {
        this.scroller.scrollToIndex(this.serialDataHistory.length - 1);
      }, 50);
    }
  }
  
  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => { resolve(); }, ms);
    });
  }
  
  /**
   * 删除指令
   */
  private async deleteCommand(id: string) {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这条指令吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: async () => {
          await this.commandManager.deleteCommand(id);
        }
      }
    });
  }
  
  /**
   * 清空历史
   */
  private clearHistory() {
    this.bluetoothManager.clearDataHistory();
    this.serialDataHistory = [];
  }
}
