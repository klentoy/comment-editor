//+------------------------------------------------------------------+
//|                                                             DSTE |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "JAson.mqh"

#include <Trade\Trade.mqh>

#include <Trade\PositionInfo.mqh>

#include <Trade\DealInfo.mqh>

#include "dste-auth.mqh"

CTrade trade;
CJAVal config;
CJAVal json;

double trailing_stop_loss = 0; // the initial trailing stop loss value
string button_id = "Button";
string stop_id = "Stop";
int phase_level = 1;
string next_order = "";
string url = "http://dstebot.com/api/expert-advisors-sec";
string transactionUrl = "http://dstebot.com/api/transactions";
string cookie = NULL, headers, _result;
double pivot_range = 0;
double phase_3_stop_loss = 0;
string initial_position = "";
bool is_started = false;
int placed_order = 0;
double orders[];
double first_grid = 0;
bool is_stop_loss = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
	// Subscribe to tick events
	if (!EventSetMillisecondTimer(500))
	{
		Print("Failed to subscribe to tick events: ", GetLastError());
		return INIT_FAILED;
	}

	ResetLastError();
	// May 31
	// config.Deserialize("{\"config\": {\"spred\": 20,\"balance\": 100000,\"pivot_1\": \"27200\",\"pivot_2\": \"27100\",\"pivot_3\": \"26720\",\"leverage\": 10,\"stop_loss\": 650,\"takeprofit\": \"2000\",\"pivot_range\": 200,\"take_profit\": 0,\"size_percent\": \"2\",\"pivot_1_grids\": 5,\"pivot_2_grids\": 5,\"tsl_tp_points\": 100000,\"stop_all_profit\": 0.1,\"pips_per_interval\": 100,\"quantity_per_grid\": 0.73},\"phase_1\": [{\"price\": 27250,\"qty\": 0.73,\"tsl\": 100000,\"stop_loss\": 26650,\"order\": 27050,\"action\": \"buy\"},{\"price\": 27050,\"qty\": 0.73,\"tsl\": 100000,\"order\": 27250,\"action\": \"sell\",\"stop_loss\": 27650}],\"phase_2\": {\"27050\": {\"qty\": 1.46,\"take_profit\": 26650,\"order\": 27250,\"action\": \"buy\",\"stop_loss\": 27650},\"27250\": {\"qty\": 1.46,\"take_profit\": 27650,\"order\": 27050,\"action\": \"sell\",\"stop_loss\": 26650}},\"phase_3\": {\"26950\": {\"qty\": 1.46,\"take_profit\": 26650,\"order\": 27350,\"action\": \"buy\",\"stop_loss\": 27650},\"27050\": {\"qty\": 0.73,\"take_profit\": 26650,\"order\": 26950,\"action\": \"sell\",\"stop_loss\": 27650},\"27250\": {\"qty\": 0.73,\"take_profit\": 27650,\"order\": 27350,\"action\": \"buy\",\"stop_loss\": 26650},\"27350\": {\"qty\": 1.46,\"take_profit\": 27650,\"stop_loss\": 26650,\"action\": \"sell\",\"order\": 26950}}}");
	// Feb 27 Test
	// config.Deserialize("{\"config\": {\"spred\": 20,\"balance\": 100000,\"pivot_1\": \"23600\",\"pivot_2\": \"23500\",\"resistance\": \"23600\",\"support\": \"23500\",\"pivot_3\": \"26720\",\"leverage\": 10,\"stop_loss\": 650,\"takeprofit\": \"2000\",\"pivot_range\": 200,\"take_profit\": 0,\"size_percent\": \"2\",\"pivot_1_grids\": 5,\"pivot_2_grids\": 5,\"tsl_tp_points\": 10000,\"stop_all_profit\": 0.1,\"pips_per_interval\": 100,\"quantity_per_grid\": 0.84},\"phase_1\": [{\"price\": 23650,\"qty\": 0.84,\"tsl\": 100000,\"stop_loss\": 23050,\"order\": 23450,\"action\": \"buy\"},{\"price\": 23450,\"qty\": 0.84,\"tsl\": 100000,\"order\": 23650,\"action\": \"sell\",\"stop_loss\": 24050}],\"phase_2\": {\"23450\": {\"qty\": 1.68,\"take_profit\": 23050,\"order\": 23650,\"action\": \"buy\",\"stop_loss\": 24050},\"23650\": {\"qty\": 1.68,\"take_profit\": 24050,\"order\": 23450,\"action\": \"sell\",\"stop_loss\": 23050}},\"phase_3\": {\"23350\": {\"qty\": 1.68,\"take_profit\": 23050,\"order\": 23750,\"action\": \"buy\",\"stop_loss\": 24050},\"23450\": {\"qty\": 0.84,\"take_profit\": 23050,\"order\": 23350,\"action\": \"sell\",\"stop_loss\": 24050},\"23650\": {\"qty\": 0.84,\"take_profit\": 24050,\"order\": 23750,\"action\": \"buy\",\"stop_loss\": 23050},\"23750\": {\"qty\": 1.68,\"take_profit\": 24050,\"stop_loss\": 23050,\"action\": \"sell\",\"order\": 23350}}}");
	// May 27 Test
	// config.Deserialize("{\"config\": {\"spred\": 20,\"balance\": 100000,\"pivot_1\": \"26800\",\"pivot_2\": \"26700\",\"pivot_3\": \"26720\",\"leverage\": 10,\"stop_loss\": 650,\"takeprofit\": \"2000\",\"pivot_range\": 200,\"take_profit\": 0,\"size_percent\": \"2\",\"pivot_1_grids\": 5,\"pivot_2_grids\": 5,\"tsl_tp_points\": 100000,\"stop_all_profit\": 0.1,\"pips_per_interval\": 100,\"quantity_per_grid\": 0.74},\"phase_1\": [{\"price\": 26850,\"qty\": 0.74,\"tsl\": 100000,\"stop_loss\": 26250,\"order\": 26650,\"action\": \"buy\"},{\"price\": 26650,\"qty\": 0.74,\"tsl\": 100000,\"order\": 26850,\"action\": \"sell\",\"stop_loss\": 27250}],\"phase_2\": {\"26650\": {\"qty\": 1.48,\"take_profit\": 26250,\"order\": 26850,\"action\": \"buy\",\"stop_loss\": 27250},\"26850\": {\"qty\": 1.48,\"take_profit\": 27250,\"order\": 26650,\"action\": \"sell\",\"stop_loss\": 26250}},\"phase_3\": {\"26550\": {\"qty\": 1.48,\"take_profit\": 26250,\"order\": 26950,\"action\": \"buy\",\"stop_loss\": 27250},\"26650\": {\"qty\": 0.74,\"take_profit\": 26250,\"order\": 26550,\"action\": \"sell\",\"stop_loss\": 27250},\"26850\": {\"qty\": 0.74,\"take_profit\": 27250,\"order\": 26950,\"action\": \"buy\",\"stop_loss\": 26250},\"26950\": {\"qty\": 1.48,\"take_profit\": 27250,\"stop_loss\": 26250,\"action\": \"sell\",\"order\": 26550}}}");
	// April 05 test
	// config.Deserialize("{\"config\":{\"spred\":20,\"balance\":100000,\"takeprofit\":20000,\"pivot_1\":28400,\"pivot_2\":28300,\"pivot_3\":28300,\"leverage\":10,\"stop_loss\":650,\"pivot_range\":200,\"take_profit\":0,\"size_percent\":1,\"pivot_1_grids\":5,\"pivot_2_grids\":5,\"tsl_tp_points\":10000,\"stop_all_profit\":0.1,\"pips_per_interval\":100,\"quantity_per_grid\":0.35},\"phase_1\":[{\"price\":28450,\"qty\":0.35,\"tsl\":100000,\"stop_loss\":27850,\"order\":28250,\"action\":\"buy\"},{\"price\":28250,\"qty\":0.35,\"tsl\":100000,\"order\":28450,\"action\":\"sell\",\"stop_loss\":28850}],\"phase_2\":{\"28450\":{\"qty\":0.7,\"take_profit\":28850,\"order\":28250,\"action\":\"sell\",\"stop_loss\":27850},\"28250\":{\"qty\":0.7,\"take_profit\":27850,\"order\":28450,\"action\":\"buy\",\"stop_loss\":28850}},\"phase_3\":{\"28450\":{\"qty\":0.35,\"take_profit\":28850,\"order\":28550,\"action\":\"buy\",\"stop_loss\":27850},\"28550\":{\"qty\":0.7,\"take_profit\":28850,\"stop_loss\":27850,\"action\":\"sell\",\"order\":28150},\"28150\":{\"qty\":0.7,\"take_profit\":27850,\"order\":28550,\"action\":\"buy\",\"stop_loss\":28850},\"28250\":{\"qty\":0.35,\"take_profit\":27850,\"order\":28150,\"action\":\"sell\",\"stop_loss\":28850}}}");
	// init_orders();
	draw_panel();

	return (INIT_SUCCEEDED);
}

// void OnTimer()
//{
//    // Place your order when the desired time is reached
//    if (TimeLocal() >= D'2023.05.26 17:20:31')
//    {
//       init_orders();
//    }
// }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
	ObjectDelete(0, button_id);
	ObjectDelete(0, stop_id);
	EventKillTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
				  const long &lparam,
				  const double &dparam,
				  const string &sparam)
{
	//--- Check the event by pressing a mouse button
	if (id == CHARTEVENT_OBJECT_CLICK && sparam == button_id)
	{
		fetch_config();
	}

	//--- Check the event by pressing a mouse button
	if (id == CHARTEVENT_OBJECT_CLICK && sparam == stop_id)
	{
		ObjectSetInteger(0, button_id, OBJPROP_BGCOLOR, clrGray);
		ObjectSetString(0, button_id, OBJPROP_TEXT, "START");
		is_started = false;
		placed_order = 0;
		close_all_orders();
	}
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fetch_config()
{

	int accountID = AccountInfoInteger(ACCOUNT_LOGIN);
	string headersJ = "Content-Type: application/json\r\n";
	char serverResult[];
	string serverHeaders;

	string serializedJson = StringFormat("{\"mt5_account_id\": %d}", accountID);

	char post[];
	StringToCharArray(serializedJson, post);

	char resulta[], result[];
	string serverHeader;

	// char post[], result[];
	ObjectSetInteger(0, button_id, OBJPROP_BGCOLOR, clrRed);
	// int res = WebRequest("POST", url, cookie, NULL, 500, post, 0, result, headers);

	int res = WebRequest("POST", url, "", headersJ, 5000, post, ArraySize(post), result, serverHeader);

	if (res == -1)
	{
		Print("Error in WebRequest. Error code  =", GetLastError());
		//--- Perhaps the URL is not listed, display a message about the necessity to add the address
		MessageBox("Add the address '" + url + "' to the list of allowed URLs on tab 'Expert Advisors'", "Error", MB_ICONINFORMATION);
	}
	else
	{
		if (res == 200)
		{
			config.Deserialize(result);
			Print(_result);
			ObjectSetInteger(0, button_id, OBJPROP_BGCOLOR, clrGreen);
			ObjectSetString(0, button_id, OBJPROP_TEXT, "STARTED");
			init_orders();
		}
		else if (res == 401)
		{
			PrintFormat("Invalid MT5 Account ID");
		}
		else
			PrintFormat("Downloading '%s' failed, error code %d", url, res);
	}

	Print("WebRequest =", res);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void init_orders()
{
	trailing_stop_loss = config["config"]["tsl_tp_points"].ToDbl();
	pivot_range = 200;
	placed_order = 0;

	double current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);

	if (current_price >= config["config"]["resistance"].ToDbl())
	{
		initial_position = "top";
	}
	else if (current_price <= config["config"]["support"].ToDbl())
	{
		initial_position = "bottom";
	}
	else
	{
		initial_position = "middle";
	}
	is_started = true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
	CPositionInfo position;

	if (PositionsTotal() > 1 && placed_order != 5)
	{
		return;
	}

	if (OrdersTotal() == 0 && PositionsTotal() == 0 && is_started && placed_order != 5)
	{
		double current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
		double volume = config["config"]["quantity_per_grid"].ToDbl();
		double price = 0;
		double buy_addition = 0;
		double sell_addtion = 0;
		Print("Price: ", price, " Resitance: ", config["config"]["resistance"].ToDbl(), " Support: ", config["config"]["support"].ToDbl());
		if (initial_position == "top" && current_price <= config["config"]["resistance"].ToDbl())
		{
			price = config["config"]["resistance"].ToDbl();
			buy_addition = 100;
			sell_addtion = -50;
		}
		else if (initial_position == "bottom" && current_price >= config["config"]["support"].ToDbl())
		{
			price = config["config"]["support"].ToDbl();
			buy_addition = 50;
			sell_addtion = -100;
		}
		else
		{
			if (current_price >= config["config"]["resistance"].ToDbl())
			{
				price = config["config"]["resistance"].ToDbl();
				buy_addition = 100;
				sell_addtion = -50;
			}
			else if (current_price <= config["config"]["support"].ToDbl())
			{
				price = config["config"]["support"].ToDbl();
				buy_addition = 50;
				sell_addtion = -100;
			}
		}

		if (price != 0)
		{
			double buy_tp = price + (buy_addition) + (pivot_range * 2);
			double sell_tp = price + (sell_addtion) + (pivot_range * -2);

			placeOrder(volume, price + sell_addtion, _Symbol, price + sell_addtion + (pivot_range * 3), sell_tp, "Phase 1 Sell", "sell", false);
			placeOrder(volume, price + buy_addition, _Symbol, price + buy_addition - (pivot_range * 3), buy_tp, "Phase 1 Buy", "buy", false);
		}
	}

	for (int i = PositionsTotal() - 1; i >= 0; i--)
	{
		ulong position_ticket = PositionGetTicket(i);
		if (PositionGetDouble(POSITION_TP) == 0 || PositionsTotal() == 1)
		{
			// Normalize trailing stop value to the point value.
			double stop_loss = trailing_stop_loss * _Point;
			double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
			double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
			double current_stop_loss = PositionGetDouble(POSITION_SL);
			double take_profit = PositionGetDouble(POSITION_TP);
			double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
			double currentStopLoss = open_price - trailing_stop_loss * Point();

			if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && NormalizeDouble(open_price + stop_loss, _Digits) < bid)
			{
				if ((stop_loss != 0) && (current_stop_loss < NormalizeDouble(bid - stop_loss, _Digits) || current_stop_loss == 0.0))
				{
					trade.PositionModify(position_ticket, NormalizeDouble(bid - stop_loss, _Digits), take_profit);
					is_stop_loss = true;
				}
			}
			else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && NormalizeDouble(open_price - stop_loss, _Digits) > ask)
			{
				if ((stop_loss != 0) && ((current_stop_loss > NormalizeDouble(ask + stop_loss, _Digits)) || (current_stop_loss == 0)))
				{
					trade.PositionModify(position_ticket, NormalizeDouble(ask + stop_loss, _Digits), take_profit);
					is_stop_loss = true;
				}
			}
		}
	}
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
						const MqlTradeRequest &request,
						const MqlTradeResult &result)
{
	string trans_symbol = trans.symbol;
	double open_price;
	double volume;
	double stop_loss;
	double take_profit;
	string type;
	double additional_price;

	switch (trans.type)
	{
	case TRADE_TRANSACTION_DEAL_ADD: // position modification
	{
		long reason = -1;
		ulong pos_ID = trans.position;
		CDealInfo m_deal;
		Print("Type: ", trans.deal_type);
		if (HistoryDealSelect(trans.deal))
		{
			m_deal.Ticket(trans.deal);
			m_deal.InfoInteger(DEAL_REASON, reason);
			Print("DEAL CLOSED REASON: ", EnumToString((ENUM_DEAL_REASON)reason));

			if ((ENUM_DEAL_REASON)reason == DEAL_REASON_TP)
			{
				Alert("Deal Closed - Take Profit Triggered");
				volume = config["config"]["quantity_per_grid"].ToDbl();
				type = trans.deal_type == 1 ? "sell" : "buy";
				double price = GetClosestValue(trans.price_tp);
				if ((price + 100) == orders[6])
				{
					refillOrder(volume, orders[6] + 12, _Symbol, orders[8] + 100, orders[6] - 100, "Refill fixed sell", "sell");
				}
				else if ((price - 100) == orders[7])
				{
					refillOrder(volume, orders[7] - 12, _Symbol, orders[9] - 100, orders[7] + 100, "Refill fixed buy", "buy");
				}

				if ((price + 100) == orders[12] || (price - 100) == orders[12])
				{
					refillOrder(volume, orders[12] + 12, _Symbol, orders[9] - 100, orders[12] + 100, "Buy double grid center", "buy", false);
					refillOrder(volume, orders[12] - 12, _Symbol, orders[8] + 100, orders[12] - 100, "Sell double grid center", "sell", false);
				}

				if ((price + 100) == first_grid || (price - 100) == first_grid)
				{
					refillOrder(volume, first_grid + 12, _Symbol, orders[9] - 100, first_grid + 100, "Buy double first grid", "buy", false);
					refillOrder(volume, first_grid - 12, _Symbol, orders[8] + 100, first_grid - 100, "Sell double first grid", "sell", false);
				}

				refillOrder(volume, price + 112, _Symbol, orders[9] - 100, price + 200, "Refill buy", "buy");
				refillOrder(volume, price - 112, _Symbol, orders[8] + 100, price - 200, "Refill sell", "sell");

				return;
			}
			else if ((ENUM_DEAL_REASON)reason == DEAL_REASON_SL)
			{
				Print("Total Position: ", PositionsTotal());
				if (PositionsTotal() == 2 && placed_order == 2)
				{
					for (int i = PositionsTotal() - 1; i >= 0; i--)
					{
						ulong position_ticket = PositionGetTicket(i);
						open_price = PositionGetDouble(POSITION_PRICE_OPEN);
						volume = config["config"]["quantity_per_grid"].ToDbl();
						type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "buy" : "sell";
						additional_price = type == "buy" ? 100 : -100;
						take_profit = PositionGetDouble(POSITION_TP);
						stop_loss = PositionGetDouble(POSITION_SL);
						placeOrder(volume, open_price, _Symbol, stop_loss, take_profit, "Phase 3 " + type, type);
						placed_order = 3;
					}
					return;
				}

				if (is_stop_loss)
				{
					Alert("Deal Closed - Stop Loss Triggered");
					close_all_orders();
					return;
				}
			}
		}

		if ((ENUM_DEAL_REASON)reason != DEAL_REASON_EXPERT)
		{
			return;
		}

		if (PositionsTotal() == 1)
		{
			ulong OrderTicket = OrderGetTicket(0);

			volume = config["config"]["quantity_per_grid"].ToDbl();
			type = OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP ? "buy" : "sell";
			trade.OrderDelete(OrderTicket);
			ulong PositionTicket = PositionGetTicket(0);
			open_price = PositionGetDouble(POSITION_PRICE_OPEN);
			stop_loss = PositionGetDouble(POSITION_TP);
			take_profit = PositionGetDouble(POSITION_SL);
			additional_price = type == "buy" ? 200 : -200;
			open_price = open_price + additional_price;

			placed_order++;
			placeOrder(volume, open_price, _Symbol, stop_loss, take_profit, "Phase 2 " + type, type);

			if (placed_order == 1)
			{
				phase_3_stop_loss = (open_price + PositionGetDouble(POSITION_PRICE_OPEN)) / 2;

				for (int x = 1; x <= 6; x++)
				{
					double addtional_price = 100 * x;
					Print("Price:", phase_3_stop_loss + addtional_price);
					PushValueIntoArray(phase_3_stop_loss + addtional_price);
					PushValueIntoArray(phase_3_stop_loss - addtional_price);
				}
				PushValueIntoArray(phase_3_stop_loss);
				first_grid = GetClosestValue(open_price);
				if (type == "sell")
				{
					trade.SellStop(volume, open_price, _Symbol, phase_3_stop_loss, take_profit, ORDER_TIME_GTC, 0, "Phase 2 " + type);
				}
				else
				{
					trade.BuyStop(volume, open_price, _Symbol, phase_3_stop_loss, take_profit, ORDER_TIME_GTC, 0, "Phase 2 " + type);
				}
				placed_order = 2;
			}

			return;
		}

		if (PositionsTotal() == 3 && placed_order == 3)
		{
			string deal_type = trans.deal_type == 0 ? "buy" : "sell";
			ulong position_ticket = PositionGetTicket(0);
			type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "buy" : "sell";

			if (deal_type != type)
			{
				placed_order = 4;
				open_price = PositionGetDouble(POSITION_PRICE_OPEN);
				volume = volume = config["config"]["quantity_per_grid"].ToDbl() * 2;
				stop_loss = PositionGetDouble(POSITION_SL);
				take_profit = PositionGetDouble(POSITION_TP);
				additional_price = type == "buy" ? 100 : -100;
				placeOrder(volume, phase_3_stop_loss, _Symbol, stop_loss, take_profit, "Phase 3 " + type, type);
				return;
			}
		}

		if (PositionsTotal() == 5)
		{
			placed_order = 5;
		}

		if (placed_order == 5)
		{
			for (int i = PositionsTotal() - 1; i >= 0; i--)
			{
				ulong position_ticket = PositionGetTicket(i);
				type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "buy" : "sell";
				additional_price = type == "buy" ? 100 : -100;
				if (PositionGetDouble(POSITION_TP) == 0)
				{
					return;
				}
				take_profit = PositionGetDouble(POSITION_PRICE_OPEN) + additional_price;
				double closest_order_price = GetClosestValue(PositionGetDouble(POSITION_PRICE_OPEN) + additional_price);
				Print("closest_order_price: ", closest_order_price, " take_profit:", take_profit);
				Print("Difference: ", take_profit - closest_order_price);
				if ((take_profit - closest_order_price) < 0 && type == "sell")
				{
					take_profit = closest_order_price;
				}

				if ((take_profit - closest_order_price) > 0 && type == "buy")
				{
					take_profit = closest_order_price;
				}

				trade.PositionModify(position_ticket, PositionGetDouble(POSITION_SL), take_profit);
			}
		}

		int accountID = AccountInfoInteger(ACCOUNT_LOGIN);
		double profit = (trans.price - open_price) * volume;
		string post_data = "symbol=" + trans.symbol +
						   "&account=" + accountID +
						   "&volume=" + DoubleToString(trans.volume) +
						   "&type=" + type +
						   "&profit=" + DoubleToString(profit) +
						   "&time=" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) +
						   "&status=" + (result.retcode == TRADE_RETCODE_DONE ? "Success" : "Failed") +
						   "&reason=" + (result.retcode == TRADE_RETCODE_DONE ? "" : IntegerToString(result.retcode));

		// Convert string data to a char array
		uchar post_data_char[];
		StringToCharArray(post_data, post_data_char);

		// Prepare the headers for the HTTP request
		string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
		uchar headers_char[];
		StringToCharArray(headers, headers_char);

		// Prepare the arrays to receive the server's response
		uchar server_response[];
		string server_response_string;

		char result[];
		string serverHeader;

		// Send the HTTP POST request to the API
		int res = WebRequest("POST", transactionUrl, "", headers, 5000, post_data_char, ArraySize(post_data_char), result, serverHeader);

		// Check the result of the WebRequest call
		if (res == -1)
		{
			Print("WebRequest failed. Error code: ", GetLastError());
		}
		else
		{
			// Convert the server's response from a char array to a string
			CharArrayToString(server_response, server_response_string);
			Print("Server response: ", server_response_string);
		}

		Print("QWIEWOQEIJQWOEIWQJEWQOIEJWQOEIJ");
	}

	break;
	}
}

void PushValueIntoArray(double value)
{
	int arraySize = ArraySize(orders);
	ArrayResize(orders, arraySize + 1);
	orders[arraySize] = value;
}

double GetClosestValue(double target)
{
	double closestValue = orders[0];
	double minDifference = MathAbs(orders[0] - target);

	for (int i = 1; i < ArraySize(orders); i++)
	{
		double difference = MathAbs(orders[i] - target);

		if (difference < minDifference)
		{
			closestValue = orders[i];
			minDifference = difference;
		}
	}

	return closestValue;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void placeOrder(double volume, double price, string symbol, double sl, double tp, string comment = "", string type = "", bool alert = true)
{
	bool has_order = false;

	for (int i = 0; i < OrdersTotal(); i++)
	{
		ulong OrderTicket = OrderGetTicket(i);
		double open_price = OrderGetDouble(ORDER_PRICE_OPEN);
		double order_volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
		if (open_price == price)
		{
			Print("Duplicate Order | Total Orders: ", OrdersTotal());
			has_order = true;
			break;
		}
	}

	if (has_order)
	{
		return;
	}

	if (type == "sell")
	{
		trade.SellStop(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
	}
	else
	{
		trade.BuyStop(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
	}
	if (alert)
	{
		Alert(comment + " Order Placed");
	}
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void refillOrder(double volume, double price, string symbol, double sl, double tp, string comment = "", string type = "", bool alert = true)
{
	bool has_order = false;

	for (int i = 0; i < OrdersTotal(); i++)
	{
		ulong OrderTicket = OrderGetTicket(i);
		double open_price = OrderGetDouble(ORDER_PRICE_OPEN);
		string order_type = OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP || OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT ? "buy" : "sell";
		double closest_open_price = GetClosestValue(open_price);
		if ((closest_open_price == orders[12] || closest_open_price == first_grid) && closest_open_price == GetClosestValue(price))
		{
			if (order_type == type)
			{
				has_order = true;
				break;
			}
			continue;
		}
		if (closest_open_price == GetClosestValue(price))
		{
			Print("Duplicate Order | Price: ", price, " Order Price: ", open_price);
			has_order = true;
			break;
		}
	}

	for (int i = 0; i < PositionsTotal(); i++)
	{
		ulong OrderTicket = PositionGetTicket(i);
		double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
		string order_type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "buy" : "sell";
		double closest_open_price = GetClosestValue(open_price);
		if ((closest_open_price == orders[12] || closest_open_price == first_grid) && closest_open_price == GetClosestValue(price))
		{
			if (order_type == type)
			{
				has_order = true;
				break;
			}
			continue;
		}
		if (GetClosestValue(open_price) == GetClosestValue(price))
		{
			Print("Duplicate Order | Price: ", price, " Order Price: ", open_price);
			has_order = true;
			break;
		}
	}

	if (has_order || GetClosestValue(price) > orders[8] || GetClosestValue(price) < orders[9])
	{
		return;
	}

	if (GetClosestValue(price) == orders[8] || GetClosestValue(price) == orders[9])
	{
		tp = 0;
	}

	double current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);

	if (type == "sell")
	{
		if (current_price <= price)
		{
			trade.SellLimit(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
		}
		else
		{
			trade.SellStop(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
		}
	}
	else
	{
		if (current_price >= price)
		{
			trade.BuyLimit(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
		}
		else
		{
			trade.BuyStop(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
		}
	}

	if (alert)
	{
		Alert(comment + " Order Placed");
	}
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void close_all_orders()
{
	is_started = false;
	ObjectSetInteger(0, button_id, OBJPROP_BGCOLOR, clrGray);
	ObjectSetString(0, button_id, OBJPROP_TEXT, "RESTART");

	for (int i = OrdersTotal() - 1; i >= 0; i--)
	{
		trade.OrderDelete(OrderGetTicket(i));
	}

	for (int i = PositionsTotal() - 1; i >= 0; i--)
	{
		trade.PositionClose(PositionGetTicket(i));
	}
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void draw_panel()
{
	//--- Create a button to send custom events
	ObjectCreate(0, button_id, OBJ_BUTTON, 0, 30, 30);
	ObjectSetInteger(0, button_id, OBJPROP_COLOR, clrWhite);
	ObjectSetInteger(0, button_id, OBJPROP_BGCOLOR, clrGray);
	ObjectSetInteger(0, button_id, OBJPROP_XDISTANCE, 50);
	ObjectSetInteger(0, button_id, OBJPROP_YDISTANCE, 200);
	ObjectSetInteger(0, button_id, OBJPROP_XSIZE, 200);
	ObjectSetInteger(0, button_id, OBJPROP_YSIZE, 50);
	ObjectSetString(0, button_id, OBJPROP_FONT, "Arial");
	ObjectSetString(0, button_id, OBJPROP_TEXT, "START");
	ObjectSetInteger(0, button_id, OBJPROP_FONTSIZE, 10);
	ObjectSetInteger(0, button_id, OBJPROP_SELECTABLE, 0);

	//--- Create a button to send custom events
	ObjectCreate(0, stop_id, OBJ_BUTTON, 0, 30, 30);
	ObjectSetInteger(0, stop_id, OBJPROP_COLOR, clrWhite);
	ObjectSetInteger(0, stop_id, OBJPROP_BGCOLOR, clrGray);
	ObjectSetInteger(0, stop_id, OBJPROP_XDISTANCE, 300);
	ObjectSetInteger(0, stop_id, OBJPROP_YDISTANCE, 200);
	ObjectSetInteger(0, stop_id, OBJPROP_XSIZE, 200);
	ObjectSetInteger(0, stop_id, OBJPROP_YSIZE, 50);
	ObjectSetString(0, stop_id, OBJPROP_FONT, "Arial");
	ObjectSetString(0, stop_id, OBJPROP_TEXT, "STOP");
	ObjectSetInteger(0, stop_id, OBJPROP_FONTSIZE, 10);
	ObjectSetInteger(0, stop_id, OBJPROP_SELECTABLE, 0);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
