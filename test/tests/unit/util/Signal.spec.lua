local function AwaitCondition(predicate, timeout)
	local start = os.clock()
	timeout = (timeout or 10)
	while (true) do
		if (predicate()) then return true end
		if ((os.clock() - start) > timeout) then return false end
		wait()
	end
end

return function()

	local Knit = require(game:GetService("ReplicatedStorage").Knit)
	local Signal = require(Knit.Util.Signal)
	local Maid = require(Knit.Util.Maid)

	describe("Constructor", function()

		it("should create a new signal and fire it", function()
			local signal = Signal.new()
			expect(Signal.Is(signal)).to.equal(true)
			spawn(function()
				signal:Fire(10, 20)
			end)
			local n1, n2 = signal:Wait()
			expect(n1).to.equal(10)
			expect(n2).to.equal(20)
			signal:Destroy()
		end)

		it("should create a new signal and clean it up with a maid", function()
			local maid = Maid.new()
			local signal = Signal.new(maid)
			expect(Signal.Is(signal)).to.equal(true)
			signal:Connect(function() end)
			expect(#signal._connections).to.equal(1)
			maid:Destroy()
			expect(#signal._connections).to.equal(0)
			signal:Destroy()
		end)

		it("should create a proxy signal and connect to it", function()
			local signal = Signal.Proxy(game:GetService("RunService").Heartbeat)
			expect(Signal.Is(signal)).to.equal(true)
			local fired = false
			signal:Connect(function()
				fired = true
			end)
			expect(AwaitCondition(function() return fired end, 2)).to.equal(true)
			signal:Destroy()
		end)

	end)

	describe("Fire", function()

		it("should be able to fire primitive argument", function()
			local signal = Signal.new()
			local send = 10
			local value
			signal:Connect(function(v)
				value = v
			end)
			signal:Fire(send)
			expect(AwaitCondition(function() return (send == value) end, 1)).to.equal(true)
			signal:Destroy()
		end)

		it("should be able to fire a reference based argument", function()
			local signal = Signal.new()
			local send = {10, 20}
			local value
			signal:Connect(function(v)
				value = v
			end)
			signal:Fire(send)
			expect(AwaitCondition(function() return (send == value) end, 1)).to.equal(true)
			signal:Destroy()
		end)

		it("should fire handlers even if destroyed immediately after", function()
			local signal = Signal.new()
			local value = false
			signal:Connect(function()
				value = true
			end)
			signal:Fire()
			signal:Destroy()
			expect(AwaitCondition(function() return value == true end, 1)).to.equal(true)
		end)

	end)

	describe("Wait", function()

		it("should be able to wait for a signal to fire", function()
			local signal = Signal.new()
			spawn(function()
				signal:Fire(10, 20, 30)
			end)
			local n1, n2, n3 = signal:Wait()
			expect(n1).to.equal(10)
			expect(n2).to.equal(20)
			expect(n3).to.equal(30)
			signal:Destroy()
		end)

		it("should wait for signal even if destroyed right after firing", function()
			local signal = Signal.new()
			spawn(function()
				signal:Fire(10, 20, 30)
				signal:Destroy()
			end)
			local n1, n2, n3 = signal:Wait()
			expect(n1).to.equal(10)
			expect(n2).to.equal(20)
			expect(n3).to.equal(30)
		end)

	end)

	describe("WaitPromise", function()

		it("should wait for a signal using a promise", function()
			local signal = Signal.new()
			spawn(function()
				signal:Fire(50, 80, 100)
			end)
			local success, n1, n2, n3 = signal:WaitPromise():Await()
			expect(success).to.equal(true)
			expect(n1).to.equal(50)
			expect(n2).to.equal(80)
			expect(n3).to.equal(100)
			signal:Destroy()
		end)

	end)

	describe("DisconnectAll", function()

		it("should disconnect all connections", function()
			local signal = Signal.new()
			local con1 = signal:Connect(function() end)
			local con2 = signal:Connect(function() end)
			expect(#signal._connections).to.equal(2)
			expect(con1:IsConnected()).to.equal(true)
			expect(con2:IsConnected()).to.equal(true)
			signal:DisconnectAll()
			expect(#signal._connections).to.equal(0)
			expect(con1:IsConnected()).to.equal(false)
			expect(con2:IsConnected()).to.equal(false)
			signal:Destroy()
		end)

		it("should properly fire events with multiple disconnects", function()
			local signal = Signal.new()
			local c1, c2, c3 = 0, 0, 0
			signal:Connect(function() c1 += 1 end)
			signal:Fire()
			signal:DisconnectAll()
			signal:Connect(function() c2 += 1 end)
			signal:Fire()
			signal:DisconnectAll()
			signal:Connect(function() c3 += 1 end)
			signal:Fire()
			signal:Destroy()
			AwaitCondition(function() return c1 > 0 end, 1)
			AwaitCondition(function() return c2 > 0 end, 1)
			AwaitCondition(function() return c3 > 0 end, 1)
			expect(c1).to.equal(1)
			expect(c2).to.equal(1)
			expect(c3).to.equal(1)
		end)

	end)

	describe("Disconnect", function()

		it("should disconnect connection", function()
			local signal = Signal.new()
			local con = signal:Connect(function() end)
			expect(#signal._connections).to.equal(1)
			expect(con:IsConnected()).to.equal(true)
			con:Disconnect()
			expect(#signal._connections).to.equal(0)
			expect(con:IsConnected()).to.equal(false)
			signal:Destroy()
		end)

	end)

end