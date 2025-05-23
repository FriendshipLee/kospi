<%@page import="news.NewsVO"%>
<%@page import="news.NewsDAO"%>
<%@page import="com.fasterxml.jackson.databind.ObjectMapper"%>
<%@page import="java.util.List"%>
<%@page import="chart.ChartVO"%>
<%@page import="chart.ChartDAO"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ include file = "header.jsp" %>
<%
	ChartDAO dao = new ChartDAO();
	List<ChartVO> clist = dao.chart();
	ObjectMapper mapper = new ObjectMapper();
	String jsonText = mapper.writeValueAsString(clist);
	
	NewsDAO ndao = new NewsDAO();
	List<NewsVO> nlist = ndao.newsResultList();
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="./resources/css/home.css"></link>
</head>
<body>
	<div class="wrap">
		<div class="chart-container">
			<h2>KOSPI 지수</h2>
			<canvas id="chart"></canvas>
		</div>
		<div class="analyze">
			<h2>최근 뉴스 분석</h2>
			<div class="content-box">
			<% for(int i = 0; i < 6; i++){ 
				NewsVO vo = nlist.get(i);
			%>
				<div class="content" onclick="window.open('post.jsp?no=<%=vo.getNo() %>')">
					<span><%=vo.getName() %></span> <span class="date"><%=vo.getDate() %></span>
					<h3><%=vo.getTitle() %></h3>
					<div class="keyword">
						<%
							List<String> keywords = vo.getKeywords();
							if (keywords != null && !keywords.isEmpty()) {
								int limit = Math.min(keywords.size(), 4);
						     	for (int j = 0; j < limit; j++) {
						        	String keyword = keywords.get(j);
									if (keyword == null || keyword.trim().isEmpty()){
										continue;
									}
						%>
									<div><%=keyword %></div>
						<%
								} 
							}
						%>
					</div>
					<div class="percent">
						<span>부정 <%=vo.getBad() %>%</span>
						<span>중립 <%=vo.getMid() %>%</span>
						<span>긍정 <%=vo.getGood() %>%</span>
					</div>
				</div>
			<%} %>
			</div>
		</div>
	</div>
</body>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>

let chart;  // 전역 선언
let lastMinute = "";  // 실시간 비교용 변수

let chartData = <%= jsonText %>
console.log(chartData)
const date = chartData.map(x => x.date);
const price = chartData.map(x => Number(x.price)); // 숫자형으로 변환

const filteredLabels = date.slice(-50);
const filteredPrices = price.slice(-50);

const ctx = document.getElementById("chart").getContext('2d');
chart = new Chart(ctx, {
	type : "line",
	data : {
		labels : filteredLabels,
		datasets : [{
			responsive:false,
			label : "실시간 종가",
			data : filteredPrices,
			borderWidth : 2
		}]
	},
	options: {
        responsive: true,
        maintainAspectRatio: false,
		scales: {
			x: {
				ticks: {
					callback: function(val, index, ticks) {
				    const raw = this.getLabelForValue(val);
				    return raw.length > 10 ? raw.substring(5, 16) : raw;  // 'MM-DD'만 표시
				  },
					maxRotation: 0,
					minRotation: 0
				},
				title: {
				  display: true,
				  text: '날짜 (월-일 시:분)'
				}
			}
		}
	}
});

async function getToken(){	
	const keyRes = await fetch("http://192.168.0.80:5000/api/keys");
	const keyData = await keyRes.json();
	const appKey = keyData.appkey;
	const secretKey = keyData.secretkey;
	const response = await fetch("https://api.kiwoom.com/oauth2/token", {
	  method: "POST",
	  headers: {
	    "Content-Type": "application/json;charset=UTF-8",
	  },
	  body: JSON.stringify({
		grant_type: 'client_credentials',
		appkey: appKey,
		secretkey: secretKey,
	  })
	})
	
	const result = await response.json()
	return result
}

const socket = new WebSocket("wss://api.kiwoom.com:10000/api/dostk/websocket");
console.log("?????")
socket.onopen = async () => {
    console.log("서버에 연결됨.");
    
    const token = await getToken()
    /* console.log(token) */
    
    const loginData ={
        'trnm': 'LOGIN',
        'token': token.token
   } 
    
    socket.send(JSON.stringify(loginData))
};

socket.onmessage = (event) => {
	//console.log(event.data)
	data = JSON.parse(event.data)
	if(data.trnm == "LOGIN"){
		if(data.return_msg != 0){
			console.log("로그인 실패")
			socket.close()				
		}else{
			console.log("로그인 성공")
			const data = {
			    	'trnm': 'REG',
			        'grp_no': '1',
			        'refresh': '1',
			        'data': [{
			            'item': ['001'],
			            'type': ['0J']
			        }]

				}
			socket.send(JSON.stringify(data))
		}
	}else if(data.trnm == "PING"){
		socket.send(event.data)
	}
	
	if(data.trnm == "REAL"){
		const prices = data.data[0].values["10"]
		const times = data.data[0].values["20"]
		
		const price = Number(prices.replace(/^[-+]/, "")); // 문자열 제거하고 숫자 변환
		time = String(Math.floor(times / 100));
		minute = time.slice(0, 4);
		
		if (minute !== lastMinute) {
			lastMinute = minute;

			console.log("실시간:", minute, price);

			chart.data.labels.push(time);
			chart.data.datasets[0].data.push(price);

			if (chart.data.labels.length > 30) {
				chart.data.labels.shift();
				chart.data.datasets[0].data.shift();
			}

			chart.update();
		}
		
	}
};
</script>
</html>