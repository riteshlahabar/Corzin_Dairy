cd /home/turnkeyi/public_html/corzindm.turnkeyinfotech.live
echo '--- Non-milking pen row ---'
mysql -u turnkeyi_corzindmuser -p'6rxDZAkoLEd1' -D turnkeyi_corzindm -N -e "select id,name,pan_type,milk_shifts from farmer_pans where name='pen 2 non milking';"
echo '--- Non-milking pen animals ---'
mysql -u turnkeyi_corzindmuser -p'6rxDZAkoLEd1' -D turnkeyi_corzindm -N -e "select id,animal_name,tag_number,weight,default_milk_per_session,pan_id from animals where pan_id=21 and farmer_id=4 and is_active=1 order by id;"
echo '--- Non-milking pen diet plans ---'
mysql -u turnkeyi_corzindmuser -p'6rxDZAkoLEd1' -D turnkeyi_corzindm -N -e "select id,animal_id,pan_id,diet_plan_name,reference_date,body_weight,milk_production,target_dmi,planned_dry_matter,plan_quantity,consumed_quantity,remaining_quantity from feed_diet_plans where farmer_id=4 and pan_id=21 order by id desc;"
echo '--- Non-milking pen diet subtype details ---'
mysql -u turnkeyi_corzindmuser -p'6rxDZAkoLEd1' -D turnkeyi_corzindm -N -e "select id,subtype_details from feed_diet_plans where farmer_id=4 and pan_id=21 order by id desc;"
echo '--- Feedings on 2026-06-18 and 2026-06-19 for non-milking pen animals ---'
mysql -u turnkeyi_corzindmuser -p'6rxDZAkoLEd1' -D turnkeyi_corzindm -N -e "select id,animal_id,date,feeding_time,diet_plan_id,package_quantity,feeding_quantity,balance_quantity,rate_per_unit,feeding_cost,feed_subtype_details from feeding_records where farmer_id=4 and animal_id in (select id from animals where pan_id=21 and farmer_id=4 and is_active=1) and date in ('2026-06-18','2026-06-19') order by date,feeding_time,animal_id,id;"
