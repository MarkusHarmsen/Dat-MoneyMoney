-- DAT Schwacke Valuation Extension for MoneyMoney
-- Fetches the valuation from "DAT"
--
-- Username: DAT €uropa-Code®

-- MIT License

-- Copyright (c) 2023 Markus Harmsen

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


WebBanking{
  version = 0.1,
  description = "Add your cars valuation into MoneyMoney",
  services = { "DatValuation" }
}

local datECode = nil
local containerCode = nil
local connection = Connection()

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "DatValuation"
end

function InitializeSession (protocol, bankCode, username, reserved, password)
  -- Username is the DAT €uropa-Code
  datECode = username:match('^(%d%d%s?%d%d%d%s?%d%d%d%s?%d%d%d%s?%d%d%d%d)'):gsub("%s+", "")
  containerCode = username:match('%u%u%d%d%d')
end

function ListAccounts (knownAccounts)
  local account = {
    name = "Valuation",
    accountNumber = "Car DatValuation",
    currency = "EUR",
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  -- We need some specfic attributes to be set
  if ( account.attributes['mileage'] == nil ) or ( account.attributes['registrationDate'] == nil ) or ( account.attributes['zip'] == nil )
  then
    local security = {
      name = "Please setup attributes: mileage, registrationDate (YYYY-MM), zip and purchasePrice",
      currency = nil,
      market = "DatValuation",
      quantity = 1,
      price = 0
    }

    return {securities = {security}}
  end

  local params = {
    datECode = datECode,
    mileage = account.attributes['mileage'],
    containerCode = containerCode,
    registrationDate = registrationDate(account),
    zip = account.attributes['zip'],
    locale = "de-DE"
  }

  local valuation = getVehicleEvaluation(params)
  local purchasePrice = account.attributes['purchasePrice']
  local security = {
    name = valuation["ManufacturerName"] .. " " .. valuation["BaseModelName"],
    currency = nil,
    market = "DatValuation",
    quantity = 1,
    price = valuation["PurchasePriceGross"],
    purchasePrice = purchasePrice
  }

  return {securities = {security}}
end

function EndSession ()
end

function getVehicleEvaluation(params)
  local endpoint = "https://www.dat.de/typo3conf/ext/dat_shortevaluation/Resources/Public/build/backend/ffw-interactive.php"

  -- Build query
  local query = "function=getVehicleEvaluation"
  for k,v in pairs(params) do
    query = query .. "&parameters%5B" .. k .. "%5D=" .. v
  end

  local json = connection:request("GET", endpoint .. "?" .. query)

  return JSON(json):dictionary()
end

function registrationDate(account)
  return account.attributes['registrationDate'] .. "-" .. "15"
end
