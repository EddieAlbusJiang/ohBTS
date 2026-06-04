import { SerialData, DisplayMode } from '../common/Types';
import { BluetoothManager } from '../common/BluetoothManager';
import { SettingsManager } from '../common/SettingsManager';

/**
 * 常规串口页面
 */
@Component
export struct SerialPortPage {
  @State serialDataHistory: SerialData[] = [];
  @State inputText: string = '';
  @State displayMode: DisplayMode = DisplayMode.ASCII;
  
  private bluetoothManager: BluetoothManager = BluetoothManager.getInstance();
  private settingsManager: SettingsManager = SettingsManager.getInstance();
  
  aboutToAppear() {
    // 获取当前显示模式
    this.displayMode = this.settingsManager.displayMode;
    
    // 设置回调
    this.bluetoothManager.setOnDataReceived((data: SerialData) => {
      this.serialDataHistory = [...this.bluetoothManager.serialDataHistory];
    });
    
    // 监听设置变化
    this.settingsManager.setOnSettingsChange(() => {
      this.displayMode = this.settingsManager.displayMode;
    });
    
    // 加载历史数据
    this.serialDataHistory = this.bluetoothManager.serialDataHistory;
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
        
        Text(`模式: ${this.displayMode}`)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      
      Divider()
      
      // 串口数据显示区域 (60%)
      Column() {
        List() {
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
      .layoutWeight(6) // 60%
      .backgroundColor('#1E1E1E')
      .padding(8)
      
      Divider()
      
      // 输入区域 (30%)
      Column() {
        Text('输入指令')
          .fontSize(14)
          .fontColor('#999999')
          .width('100%')
          .margin({ bottom: 8 })
        
        TextArea({ placeholder: this.getInputPlaceholder(), text: this.inputText })
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#F5F5F5')
          .borderRadius(4)
          .onChange((value: string) => {
            this.inputText = value;
          })
      }
      .width('100%')
      .layoutWeight(3) // 30%
      .padding(16)
      .backgroundColor(Color.White)
      .alignItems(HorizontalAlign.Start)
      
      Divider()
      
      // 发送按钮
      Row() {
        Button('发送')
          .width('100%')
          .height(44)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .fontSize(16)
          .onClick(() => {
            this.sendData();
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
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
        .width(30)
      
      Text(this.formatTimestamp(data.timestamp))
        .fontSize(10)
        .fontColor('#888888')
        .width(80)
      
      Text(this.formatData(data))
        .fontSize(12)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
  
  /**
   * 获取输入提示
   */
  private getInputPlaceholder(): string {
    if (this.displayMode === DisplayMode.HEX) {
      return '请输入十六进制数据，如: 01 02 03 FF';
    } else {
      return '请输入ASCII文本';
    }
  }
  
  /**
   * 格式化时间戳
   */
  private formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
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
   * 发送数据
   */
  private async sendData() {
    if (!this.inputText.trim()) {
      return;
    }
    
    const isHex = this.displayMode === DisplayMode.HEX;
    const success = await this.bluetoothManager.sendData(this.inputText, isHex);
    
    if (success) {
      this.inputText = '';
      this.serialDataHistory = [...this.bluetoothManager.serialDataHistory];
    }
  }
  
  /**
   * 清空历史
   */
  private clearHistory() {
    this.bluetoothManager.clearDataHistory();
    this.serialDataHistory = [];
  }
}
