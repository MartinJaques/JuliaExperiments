using DataFrames

macro TableLookup(t,returnColumn,indexes...)
    for(ind,val) in enumerate(indexes)
        if(ind==1)
            exp= :($t[$ind].==$val)
        else
            exp = :($exp & ($t[$ind].==$val))
        end
        #@show(exp)
    end

    exp = :($t[$exp,Symbol(DataFrames.makeidentifier($returnColumn))][1])
    #exp = :($t[$exp,:])
    #@show(exp)
end

ann_spot_rate(foi) = e^(foi/100)-1
ann_spot_rate(foi,illiqPC) = (e^(foi/100)-1)*(illiqPC/100)

rfr_Table = readtable("C:\\Users\\Martin\\Documents\\Jupyter\\JuliaExperiments\\basTest.csv")
ilq_Table = readtable("C:\\Users\\Martin\\Documents\\Jupyter\\JuliaExperiments\\basTest.csv")

function v_interest_rates1(maxTerm::Integer,yeildCurve::Integer,spot_rate_freq::Integer,illiqPC::Float64)

    rfr = zeros(maxTerm)
    ilq = zeros(maxTerm)
    vsr = zeros(maxTerm)
    calc_forward_rate = zeros(maxTerm)
    t1 = zeros(maxTerm)
    t2 = zeros(maxTerm)
    s1 = zeros(maxTerm)
    s2 = zeros(maxTerm)
    fra = zeros(maxTerm)
    mfr = zeros(maxTerm)

    for t in 1:maxTerm

        rfr[t] = ann_spot_rate(@TableLookup(rfr_Table,string(yeildCurve),t))
        ilq[t] = ann_spot_rate(@TableLookup(ilq_Table,string(yeildCurve),t),illiqPC)

        vsr[t]=rfr[t]+ilq[t]

        if mod((t-1)*spot_rate_freq,12)==0
            calc_forward_rate[t]=1
        else
            calc_forward_rate[t]=0
        end

        if calc_forward_rate[t]==1
            t1[t]=(t-1)/12
        else
            t1[t]=0
        end

        if calc_forward_rate[t]==1
            t2[t]=t/12
        else
            t2[t]=0
        end

        if t>1
          s1[t]=vsr[t-1]
        else
          s1[t]=vsr[t]
        end

        s2[t] = vsr[t]

        if calc_forward_rate[t]==1
            fra[t] = ((1+s2[t])^t2[t]/(1+s1[t])^t1[t])^(1/(t2[t]-t1[t]))-1
        else
            fra[t]= fra[t-1]
        end

        mfr[t] = (1+fra[t])^(1/12)-1
    end

    mfr
end

function v_interest_rates2(maxTerm::Integer,yeildCurve::Integer,spot_rate_freq::Integer,illiqPC::Float64)

    forward_rate = zeros(maxTerm)
    monthly_forward_rate = zeros(maxTerm)
    vsr = zeros(maxTerm)

    rfr_fofi = rfr_Table[Symbol(DataFrames.makeidentifier(string(yeildCurve)))] #can we apply the spot rate function to this as a vector?
    ilq_fofi = ilq_Table[Symbol(DataFrames.makeidentifier(string(yeildCurve)))]

    for t in 1:maxTerm

        vsr[t] = ann_spot_rate(rfr_fofi[t]) + ann_spot_rate(ilq_fofi[t],illiqPC)

        if t==1
            forward_rate[t] = vsr[t]
        elseif mod((t-1)*spot_rate_freq,12)==0
            t1 = (t-1)/12
            t2 = t/12
            s1 = vsr[t-1]
            s2 = vsr[t]

            forward_rate[t] = ((1+s2)^t2/(1+s1)^t1)^(1/(t2-t1))-1

        else
            forward_rate[t] = forward_rate[t-1]
        end

        monthly_forward_rate[t] = (1+forward_rate[t])^(1/12)-1
    end

    monthly_forward_rate
end

@time v_interest_rates1(19,201212,12,10.0)
#@step v_interest_rates1(19,201212,12,10.0)

@time v_interest_rates2(19,201212,12,10.0)
