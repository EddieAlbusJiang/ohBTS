import { BluetoothDevice, ConnectionState, SerialData, DisplayMode } from './Types';
import { access, connection, socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 蓝牙状态管理器
 * 负责管理蓝牙连接状态、设备扫描、数据收发
 */
export class BluetoothManager {
  private static instance: BluetoothManager;
  
  // 连接状态
  private _connectionState: ConnectionState = ConnectionState.DISCONNECTED;
  private _connectedDevice: BluetoothDevice | null = null;
  private _socketId: number = -1;
  
  // 扫描设备列表
  private _discoveredDevices: BluetoothDevice[] = [];
  private _isScanning: boolean = false;
  
  // 串口数据记录
  private _serialDataHistory: SerialData[] = [];
  
  // 回调函数
  private onStateChange?: (state: ConnectionState, device: BluetoothDevice | null) => void;
  private onDeviceDiscovered?: (device: BluetoothDevice) => void;
  private onDataReceived?: (data: SerialData) => void;
  
  private constructor() {}
  
  static getInstance(): BluetoothManager {
    if (!BluetoothManager.instance) {
      BluetoothManager.instance = new BluetoothManager();
    }
    return BluetoothManager.instance;
  }
  
  // Getters
  get connectionState(): ConnectionState {
    return this._connectionState;
  }
  
  get connectedDevice(): BluetoothDevice | null {
    return this._connectedDevice;
  }
  
  get discoveredDevices(): BluetoothDevice[] {
    return this._discoveredDevices;
  }
  
  get isScanning(): boolean {
    return this._isScanning;
  }
  
  get serialDataHistory(): SerialData[] {
    return this._serialDataHistory;
  }
  
  // Set callbacks
  setOnStateChange(callback: (state: ConnectionState, device: BluetoothDevice | null) => void) {
    this.onStateChange = callback;
  }
  
  setOnDeviceDiscovered(callback: (device: BluetoothDevice) => void) {
    this.onDeviceDiscovered = callback;
  }
  
  setOnDataReceived(callback: (data: SerialData) => void) {
    this.onDataReceived = callback;
  }
  
  /**
   * 初始化蓝牙
   */
  async initialize(): Promise<boolean> {
    try {
      const state = access.getState();
      if (state !== access.BluetoothState.STATE_ON) {
        access.enableBluetooth();
      }
      return true;
    } catch (error) {
      console.error('Bluetooth initialization failed:', error);
      return false;
    }
  }
  
  /**
   * 开始扫描蓝牙设备
   */
  async startDiscovery(): Promise<void> {
    if (this._isScanning) {
      return;
    }
    
    try {
      this._isScanning = true;
      this._discoveredDevices = [];
      
      // 注册设备发现回调
      connection.on('bluetoothDeviceFind', (data: Array<string>) => {
        data.forEach((deviceId: string) => {
          try {
            const deviceName = connection.getRemoteDeviceName(deviceId);
            const btDevice: BluetoothDevice = {
              deviceId: deviceId,
              deviceName: deviceName || '未知设备',
              rssi: -100
            };
            
            // 避免重复添加
            const exists = this._discoveredDevices.find(d => d.deviceId === btDevice.deviceId);
            if (!exists) {
              this._discoveredDevices.push(btDevice);
              if (this.onDeviceDiscovered) {
                this.onDeviceDiscovered(btDevice);
              }
            }
          } catch (err) {
            console.error('Get device info failed:', err);
          }
        });
      });
      
      // 开始扫描
      connection.startBluetoothDiscovery();
    } catch (error) {
      console.error('Start discovery failed:', error);
      this._isScanning = false;
    }
  }
  
  /**
   * 停止扫描
   */
  async stopDiscovery(): Promise<void> {
    try {
      connection.stopBluetoothDiscovery();
      connection.off('bluetoothDeviceFind');
      this._isScanning = false;
    } catch (error) {
      console.error('Stop discovery failed:', error);
    }
  }
  
  /**
   * 连接设备
   */
  async connectDevice(device: BluetoothDevice): Promise<boolean> {
    // 如果已连接其他设备，先断开
    if (this._connectionState === ConnectionState.CONNECTED && 
        this._connectedDevice?.deviceId !== device.deviceId) {
      await this.disconnectDevice();
    }
    
    try {
      this._connectionState = ConnectionState.CONNECTING;
      this.notifyStateChange();
      
      // 创建SPP连接
      const sppOption: socket.SppOptions = {
        uuid: '00001101-0000-1000-8000-00805F9B34FB', // SPP UUID
        secure: false,
        type: 0
      };
      
      return new Promise<boolean>((resolve) => {
        const clientSocket = (err: BusinessError, number: number) => {
          if (err) {
            console.error('SPP connect error:', err);
            this._connectionState = ConnectionState.DISCONNECTED;
            this.notifyStateChange();
            resolve(false);
          } else {
            this._socketId = number;
            this._connectedDevice = device;
            this._connectionState = ConnectionState.CONNECTED;
            this.notifyStateChange();
            
            // 开始监听数据
            this.startDataListener();
            
            resolve(true);
          }
        };
        
        try {
          socket.sppConnect(device.deviceId, sppOption, clientSocket);
        } catch (error) {
          console.error('SPP connect failed:', error);
          this._connectionState = ConnectionState.DISCONNECTED;
          this.notifyStateChange();
          resolve(false);
        }
      });
    } catch (error) {
      console.error('Connect failed:', error);
      this._connectionState = ConnectionState.DISCONNECTED;
      this.notifyStateChange();
      return false;
    }
  }
  
  /**
   * 断开设备连接
   */
  async disconnectDevice(): Promise<void> {
    if (this._connectionState === ConnectionState.DISCONNECTED) {
      return;
    }
    
    try {
      this._connectionState = ConnectionState.DISCONNECTING;
      this.notifyStateChange();
      
      if (this._socketId !== -1) {
        socket.sppCloseClientSocket(this._socketId);
        this._socketId = -1;
      }
      
      this._connectedDevice = null;
      this._connectionState = ConnectionState.DISCONNECTED;
      this.notifyStateChange();
    } catch (error) {
      console.error('Disconnect failed:', error);
      this._connectionState = ConnectionState.DISCONNECTED;
      this._connectedDevice = null;
      this.notifyStateChange();
    }
  }
  
  /**
   * 发送数据
   */
  async sendData(data: string, isHex: boolean): Promise<boolean> {
    if (this._connectionState !== ConnectionState.CONNECTED || this._socketId === -1) {
      return false;
    }
    
    try {
      let buffer: ArrayBuffer;
      
      if (isHex) {
        // Hex转ArrayBuffer
        buffer = this.hexToArrayBuffer(data);
      } else {
        // ASCII转ArrayBuffer
        buffer = this.stringToArrayBuffer(data);
      }
      
      socket.sppWrite(this._socketId, buffer);
      
      // 记录发送数据
      const serialData: SerialData = {
        content: data,
        isSend: true,
        timestamp: Date.now(),
        displayMode: isHex ? DisplayMode.HEX : DisplayMode.ASCII
      };
      this._serialDataHistory.push(serialData);
      
      return true;
    } catch (error) {
      console.error('Send data failed:', error);
      return false;
    }
  }
  
  /**
   * 开始数据监听
   */
  private startDataListener(): void {
    if (this._socketId === -1) {
      return;
    }
    
    try {
      socket.on('sppRead', this._socketId, (dataBuffer: ArrayBuffer) => {
        const receivedData = this.arrayBufferToString(dataBuffer);
        
        const serialData: SerialData = {
          content: receivedData,
          isSend: false,
          timestamp: Date.now(),
          displayMode: DisplayMode.ASCII
        };
        
        this._serialDataHistory.push(serialData);
        
        if (this.onDataReceived) {
          this.onDataReceived(serialData);
        }
      });
    } catch (error) {
      console.error('Start data listener failed:', error);
    }
  }
  
  /**
   * 通知状态变化
   */
  private notifyStateChange(): void {
    if (this.onStateChange) {
      this.onStateChange(this._connectionState, this._connectedDevice);
    }
  }
  
  /**
   * 字符串转ArrayBuffer
   */
  private stringToArrayBuffer(str: string): ArrayBuffer {
    const buffer = new ArrayBuffer(str.length);
    const view = new Uint8Array(buffer);
    for (let i = 0; i < str.length; i++) {
      view[i] = str.charCodeAt(i);
    }
    return buffer;
  }
  
  /**
   * Hex字符串转ArrayBuffer
   */
  private hexToArrayBuffer(hex: string): ArrayBuffer {
    const hexArray = hex.replace(/\s/g, '').match(/.{1,2}/g) || [];
    const buffer = new ArrayBuffer(hexArray.length);
    const view = new Uint8Array(buffer);
    for (let i = 0; i < hexArray.length; i++) {
      view[i] = parseInt(hexArray[i], 16);
    }
    return buffer;
  }
  
  /**
   * ArrayBuffer转字符串
   */
  private arrayBufferToString(buffer: ArrayBuffer): string {
    const view = new Uint8Array(buffer);
    let str = '';
    for (let i = 0; i < view.length; i++) {
      str += String.fromCharCode(view[i]);
    }
    return str;
  }
  
  /**
   * 清空数据历史
   */
  clearDataHistory(): void {
    this._serialDataHistory = [];
  }
}
