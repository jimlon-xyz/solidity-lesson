<template>
  <Layout class="layout-container">
        <Header class="layout-header">
            <span class="brand-text">区块链 · 在线众筹</span>
            <div class="account-info">
                <Button type="default" ghost @click="state.showCreateForm = true">发起众筹</Button>
                <span>{{showAccount(state.account)}}</span>
                <span>{{state.balance}} ETH</span>
            </div>
        </Header>
        <Content class="layout-content">
            <div>
                <div style="margin-bottom: 24px; display: flex; ">
                    <Input v-model="state.id" placeholder="" :style="{width: '120px', marginRight: '6px'}">
                        <template #prepend>编号</template>
                    </Input>
                    <Button type="primary" @click="goActivity">跳转</Button>
                </div>
                <Row :gutter="36">
                    <Col :span="8">
                        <img src="../assets/480x480.png" :style="{width: '100%'}"/>
                    </Col>
                    <Col :span="14">
                        <Spin v-if="state.loading" size="large" fix :show="state.loading">加载中...</Spin>
                        <template v-else>
                            <h1 class="h1">{{state.activity.title}}</h1>
                            <div>{{state.activity.description}}</div>
                            <div>发起人：<span>{{state.activity.creator}}</span></div>
                            <div>众筹金额：
                                <span class="amount">{{formatValue(state.activity.value)}}<strong>ETH</strong></span>
                                <span :style="{fontSize: '16px', marginLeft: '36px'}">最小金额：{{formatValue(state.activity.minValue)}} ETH</span>
                            </div>
                            <div>已筹集金额：<span class="amount">{{formatValue(state.activity.receiveAmount)}}<strong>ETH</strong></span></div>
                            <div style="overflow: hidden; width: 100%; ">
                                <Progress :percent="state.activity.receiveAmount / state.activity.value * 100" :stroke-width="20" status="active" text-inside />
                            </div>
                            <div>状态：
                                <Tag color="primary" v-if="state.activity.state == 0">进行中</Tag>
                                <Tag color="success" v-else-if="state.activity.state == 1">筹集成功</Tag>
                                <Tag color="error" v-else>筹集失败</Tag>
                            </div>
                            <div>截止日期：{{formatDate(state.activity.deadline)}}</div>
                            <div>
                                <Button :disabled="state.activity.state > 0" size="large" icon="md-cash" type="success" long @click="onPay">捐助</Button>
                            </div>
                            <div v-if="state.activity.creator == state.account && state.activity.state == 0">
                                <Button size="large" icon="md-checkmark-circle-outline" type="warning" long @click="onFinish">结束活动</Button>
                            </div>    
                        </template> 
                    </Col>
                </Row>
            </div>
        </Content>

        <Modal
            :width="640"
            v-model="state.showCreateForm"
            title="创建众筹活动"
            :loading="loading"
            @onOk="onCreateActivity">
            <div :style="{padding: '20px'}">
                <Form :label-width="120">
                    <FormItem label="标题">
                        <Input v-model="state.form.title" placeholder="输入众筹活动标题"></Input>
                    </FormItem>
                    <FormItem label="描述">
                        <Input v-model="state.form.description" placeholder="输入众筹活动描述" type="textarea" :rows="6"></Input>
                    </FormItem>
                    <FormItem label="筹集金额">
                        <Input v-model="state.form.value" placeholder="输入筹集金额">
                            <template #append>ETH</template>
                        </Input>
                    </FormItem>
                    <FormItem label="最小金额">
                        <Input v-model="state.form.minValue"  placeholder="输入单笔最小金额">
                            <template #append>ETH</template>
                        </Input>
                    </FormItem>
                    <FormItem label="截止日期">
                        <DatePicker v-model="state.form.deadline" type="datetime" placeholder="选择活动截止日期"/>
                    </FormItem>
                    <FormItem label="最低筹集百分比">
                        <Input v-model="state.form.minValuePercent" placeholder="输入百分比" :style="{width: '160px'}"><template #append>%</template></Input>
                    </FormItem>
                </Form>
            </div>
        </Modal>

    </Layout>
</template>

<script setup>
import { reactive, getCurrentInstance, onMounted } from "vue"
import contractABI from "../abis/contract.json"
import { Input } from 'view-ui-plus'

/** 替换成你的合约地址  */
const contractAddr = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512'

const state = reactive({
    id: null,
    account: null,
    balance: 0,
    showCreateForm: false,
    form: {},
    contract: null,
    loading: true,
    activity: {},
    value: 0,
})

let web3

const {proxy} = getCurrentInstance()

new Promise((resolve, reject) => {
    if (window.ethereum) {
        web3 = new window.Web3(window.ethereum) // provider http websocket ws
        // window.ethereum.enable()  deprecated
        window.ethereum.request({method:'eth_requestAccounts'}).then(account => {
            resolve({account, web3}) // account[] 
        })
    } else {
        reject("metamask 没有安装")
    }
}).then(main)

async function main({web3, account}) {
    state.account = web3.utils.toChecksumAddress(account[0])
    state.contract = new web3.eth.Contract(contractABI, contractAddr, {from: state.account})

    state.balance = web3.utils.fromWei(await web3.eth.getBalance(state.account), 'ether')


}

function onPay() {
    proxy.$Modal.confirm({
        title: '输入捐助的ETH金额',
        render: (h) => {
            return h( Input, {
                size: "large",
                modelValue: state.value,
                autofocus: true,
                placeholder: '输入捐助的ETH金额',
                'onInput': (event) => {
                    state.value = event.target.value
                }
            })
        },
        onOk() {
            executePay(state.value)
        }
    })
}

function onFinish() {
    state.contract.methods.finish(state.id)
   .send({from: state.account})
   .on('transactionHash', txHash => {
        console.log('txHash=', txHash)
    })
    .on('receipt', receipt => {
        console.log('receipt=',receipt)
    })
    .on('error', error => {
        console.log('error=',error)
    })
}

function executePay(ethValue) {
   state.contract.methods.pay(state.id)
   .send({from: state.account, value: web3.utils.toWei(ethValue, 'ether')})
   .on('transactionHash', txHash => {
        console.log('txHash=', txHash)
    })
    .on('receipt', receipt => {
        console.log('receipt=',receipt)
    })
    .on('error', error => {
        console.log('error=',error)
    })
}

function showAccount(account) {
    if (!account) return '连接钱包'
    return account.toString().substr(0, 5) + '...' + account.toString().substr(-4)
}

function onCreateActivity() {
    state.contract.methods.createActivity(
        [state.form.title,state.form.description],
        web3.utils.toWei(state.form.value, 'ether'),
        Math.floor(new Date(state.form.deadline).getTime() / 1000),
        web3.utils.toWei(state.form.minValue, 'ether'),
        state.form.minValuePercent
    )
    .send({from: state.account}) // 将数据写入到区块链 from: msg.sender  gas: gasPrice: 111
    .on('transactionHash', txHash => {
        console.log('txHash=', txHash)
    })
    .on('receipt', receipt => {
        console.log('receipt=',receipt)
    })
    .on('error', error => {
        console.log('error=',receipt)
    })

}

function goActivity() {
    state.loading = true
    state.contract.methods.getActivity(state.id).call().then(result => {
        console.log(result)
        if (result[0]) { // bool
            state.activity = {
                title: result[1].title,
                description: result[1].description,
                value: result[1].value,
                receiveAmount: result[1].receiveAmount,
                creator: result[1].creator,
                deadline: result[1].deadline,
                minValue: result[1].minValue,
                minValuePercent: result[1].minValuePercent,
                state: Number(result[1].state),
                finishedTime: result[1].finishedTime,
                createdAt: result[1].createdAt
            }
            state.loading = false
        }
    })
}

function formatValue(v) {
    return web3.utils.fromWei(v, 'ether')
}

function formatDate(v) {
    return proxy.$Date.unix(v).format('YYYY-MM-DD HH:mm:ss')
}

</script>

<style scoped>
.layout-container {
    height: 100%;
}

.layout-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.brand-text {
    color: #fff;
    font-size: 26px;
    font-weight: 600;
}

.account-info span {
    margin-left: 24px;
    color: #fff;
    font-size: 16px;
}

.layout-content {
    flex: 1;
    overflow: auto;
}

.layout-content > div {
    margin: 48px auto;
    max-width: 1400px;
}

.h1 {
    font-size: 36px;
    color: #222;
    margin-bottom: 24px;
}

.h1 + div {
    color: #888;
}

.h1 ~ div {
    font-size: 18px;
    margin-bottom: 24px;
}

.h1 ~ div span.amount {
    font-size: 26px;
}

.h1 ~ div span.amount strong {
    margin-left: 4px;
}
</style>
