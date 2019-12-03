From cap_machine Require Export logrel.
From iris.proofmode Require Import tactics.
From iris.program_logic Require Import weakestpre adequacy lifting.
From stdpp Require Import base.
From cap_machine Require Import ftlr_base.

Section fundamental.
  Context `{memG Σ, regG Σ, STSG Σ, logrel_na_invs Σ,
            MonRef: MonRefG (leibnizO _) CapR_rtc Σ,
            Heap: heapG Σ}.

  Notation STS := (leibnizO (STS_states * STS_rels)).
  Notation WORLD := (leibnizO (STS * STS)). 
  Implicit Types W : WORLD.

  Notation D := (WORLD -n> (leibnizO Word) -n> iProp Σ).
  Notation R := (WORLD -n> (leibnizO Reg) -n> iProp Σ).
  Implicit Types w : (leibnizO Word).
  Implicit Types interp : (D).

  (*
  Lemma jnz_case (fs : STS_states) (fr : STS_rels) (r : leibnizO Reg) (p p' : Perm) 
        (g : Locality) (b e a : Addr) (w : Word) (r1 r2 : RegName) :
    ftlr_instr fs fr r p p' g b e a w (Jnz r1 r2).
  Proof.
    intros Hp Hsome i Hbae Hfp HO Hi.
    iIntros "#IH #Hbe #Hreg #Harel #Hmono #Hw".
    iIntros "Hfull Hna Hr Ha HPC Hmap".
    rewrite delete_insert_delete.
    destruct (reg_eq_dec PC r2).
    * subst r2.
      destruct (reg_eq_dec PC r1).
      { subst r1. iApply (wp_jnz_success_jmpPC with "[$HPC $Ha]"); eauto; iFrame "#".
        iNext. iIntros "(HPC & Ha)".
        simpl. iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
        apply lookup_insert. rewrite delete_insert_delete. iFrame.
        iApply wp_pure_step_later; auto. iNext.
        (* close region *)
        iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto.
        iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto.
        destruct p; iFrame. 
        destruct Hp as [Hcontr | [Hcontr | Hcontr] ]; inversion Hcontr. }
      { destruct (Hsome r1) as [wr1 Hsomer1].
        iDestruct ((big_sepM_delete _ _ r1) with "Hmap") as "[Hr1 Hmap]".
        { rewrite lookup_delete_ne; eauto. }
        iApply (wp_jnz_success_jmpPC2 with "[$HPC $Hr1 $Ha]"); eauto.
        iNext. iIntros "(HPC & Ha & Hr1)".
        iApply wp_pure_step_later; auto.
        iDestruct ("Hreg" $! r1 ltac:(auto)) as "Hwr1".
        rewrite /RegLocate Hsomer1. 
        iDestruct ((big_sepM_delete _ _ r1) with "[Hr1 Hmap]") as "Hmap /=";
          [apply lookup_insert|rewrite delete_insert_delete;iFrame|]. simpl.
        rewrite -delete_insert_ne; auto.
        destruct (updatePcPerm wr1) eqn:Heq.
        { iApply (wp_bind (fill [SeqCtx])).
          iApply (wp_notCorrectPC with "HPC"); [intro; match goal with H: isCorrectPC (inl _) |- _ => inv H end|].
          iNext. iNext. iIntros "HPC /=".
          iApply wp_pure_step_later; auto.
          iApply wp_value.
          iNext. iIntros. discriminate. }
        { destruct c,p0,p0,p0.
          destruct p0.
          - iApply (wp_bind (fill [SeqCtx])).
            iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
            iNext. iNext. iIntros "HPC /=".
            iApply wp_pure_step_later; auto.
            iApply wp_value.
            iNext. iIntros. discriminate.
          - iApply (wp_bind (fill [SeqCtx])).
            iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
            iNext. iNext. iIntros "HPC /=".
            iApply wp_pure_step_later; auto.
            iApply wp_value.
            iNext. iIntros. discriminate.
          - iApply (wp_bind (fill [SeqCtx])).
            iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
            iNext. iNext. iIntros "HPC /=".
            iApply wp_pure_step_later; auto.
            iApply wp_value.
            iNext. iIntros. discriminate.
          - iApply (wp_bind (fill [SeqCtx])).
            iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
            iNext. iNext. iIntros "HPC /=".
            iApply wp_pure_step_later; auto.
            iApply wp_value.
            iNext. iIntros. discriminate.
          - iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
            apply lookup_insert. rewrite delete_insert_delete. iFrame.
            rewrite (insert_id r r1); auto.
            destruct wr1; simpl in Heq; try congruence.
            destruct c,p0,p0,p0,p0; try congruence.
            + inv Heq. rewrite (fixpoint_interp1_eq _ (inr _)).
              simpl. rewrite /read_write_cond.
              iNext.
              iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto.              
              iDestruct "Hwr1" as (p'') "[% [H1 H2]]".
              iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto.
            + inv Heq. rewrite (fixpoint_interp1_eq _ (inr _)).
              simpl. rewrite /enter_cond.
              rewrite /interp_expr /=.
              iDestruct "Hwr1" as "#H".
              iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
              iAssert (future_world l (fs,fr) (fs,fr)) as "Hfuture".
              { destruct l; iPureIntro;
                [apply related_sts_priv_refl|apply related_sts_pub_refl]. }
              iSpecialize ("H" $! _ (fs,fr) with "Hfuture").
              iNext.
              iDestruct "H" as (fs' fr' Heq1 Heq2) "HH". inversion Heq1. inversion Heq2.
              subst.
              iDestruct ("HH" with "[Hr Hfull Hmap Hna]") as "[_ Hx]"; iFrame; eauto.
          - iApply (wp_bind (fill [SeqCtx])).
            iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
            iNext. iNext. iIntros "HPC /=".
            iApply wp_pure_step_later; auto.
            iApply wp_value.
            iNext. iIntros. discriminate.
          - iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
            apply lookup_insert. rewrite delete_insert_delete. iFrame.
            rewrite (insert_id r r1); auto.
            iNext. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto.   
            destruct wr1; simpl in Heq; try congruence.
            destruct c,p0,p0,p0,p0; try congruence. inv Heq.
            rewrite (fixpoint_interp1_eq _ (inr _)).
            simpl. iDestruct "Hwr1" as (p'') "[% [H1 H2]]".
            iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto.
          - iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
            apply lookup_insert. rewrite delete_insert_delete. iFrame.
            rewrite (insert_id r r1); auto.
            iNext. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto.   
            destruct wr1; simpl in Heq; try congruence.
            destruct c,p0,p0,p0,p0; try congruence. inv Heq.
            rewrite (fixpoint_interp1_eq _ (inr _)).
            simpl. iDestruct "Hwr1" as (p'') "[% [H1 H2]]".
            iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto. } }
    * destruct (Hsome r2) as [wr2 Hsomer2].
      iDestruct ((big_sepM_delete _ _ r2) with "Hmap") as "[Hr2 Hmap]".
      { rewrite lookup_delete_ne; eauto. }
      case_eq (nonZero wr2); intros.
      { assert (wr2 <> inl 0%Z) by (intro; subst wr2; cbv in H3; congruence).
        destruct (reg_eq_dec PC r1).
        - subst r1. iApply (wp_jnz_success_jmpPC1 with "[$HPC $Hr2 $Ha]"); eauto. 
          iNext. iIntros "(HPC & Ha & Hr2)".
          iApply wp_pure_step_later; auto.
          simpl. iDestruct ((big_sepM_delete _ _ r2) with "[Hr2 Hmap]") as "Hmap /=";
          [apply lookup_insert|rewrite delete_insert_delete;iFrame|]. simpl.
          rewrite -delete_insert_ne; auto.
          iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
          apply lookup_insert. rewrite delete_insert_delete. iFrame.
          rewrite (insert_id r r2); auto.
          iNext. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
          iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto.
          destruct p; iFrame. 
          destruct Hp as [Hcontr | [Hcontr | Hcontr] ]; inversion Hcontr.
        - destruct (reg_eq_dec r2 r1).
          + subst r1. iApply (wp_jnz_success_jmp2 with "[$HPC $Hr2 $Ha]"); eauto. 
            iNext. iIntros "(HPC & Ha & Hr2)".
            iApply wp_pure_step_later; auto.
            simpl. iDestruct ((big_sepM_delete _ _ r2) with "[Hr2 Hmap]") as "Hmap /=";
                     [apply lookup_insert|rewrite delete_insert_delete;iFrame|]. simpl.
            rewrite -delete_insert_ne; auto.
            rewrite (insert_id r r2); auto.
            destruct (updatePcPerm wr2) eqn:Heq.
            { iApply (wp_bind (fill [SeqCtx])).
              iApply (wp_notCorrectPC with "HPC"); [intro; match goal with H: isCorrectPC (inl _) |- _ => inv H end|].
              iNext. iNext. iIntros "HPC /=".
              iApply wp_pure_step_later; auto.
              iApply wp_value.
              iNext. iIntros. discriminate. }
            { destruct c,p0,p0,p0.
              destruct p0.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
                apply lookup_insert. rewrite delete_insert_delete. iFrame.
                iDestruct ("Hreg" $! r2 ltac:(auto)) as "Hwr2".
                rewrite /RegLocate Hsomer2.
                destruct wr2; simpl in Heq; try congruence.
                destruct c,p0,p0,p0,p0; try congruence.
                + inv Heq. rewrite (fixpoint_interp1_eq _ (inr _)).
                  simpl. rewrite /read_write_cond.
                  iDestruct "Hwr2" as (p'') "[% [H1 H2]]".
                  iNext. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
                  iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto.
                + inv Heq. rewrite (fixpoint_interp1_eq _ (inr _)).
                  simpl. rewrite /enter_cond.
                  rewrite /interp_expr /=.
                  iDestruct "Hwr2" as "#H".
                  iAssert (future_world l (fs,fr) (fs,fr)) as "Hfuture".
                  { destruct l; iPureIntro;
                      [apply related_sts_priv_refl|apply related_sts_pub_refl]. }
                  iSpecialize ("H" $! _ (fs,fr) with "Hfuture").
                  iNext.
                  iDestruct "H" as (fs' fr' Heq1 Heq2) "HH". inversion Heq1. inversion Heq2.
                  subst. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
                  iDestruct ("HH" with "[Hr Hfull Hmap Hna]") as "[_ Hx]"; iFrame; eauto.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
                apply lookup_insert. rewrite delete_insert_delete. iFrame.
                iNext. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
                destruct wr2; simpl in Heq; try congruence.
                destruct c,p0,p0,p0,p0; try congruence. inv Heq.
                iDestruct ("Hreg" $! r2 ltac:(auto)) as "Hwr2".
                rewrite /RegLocate Hsomer2 /=. rewrite (fixpoint_interp1_eq _ (inr _)).
                simpl. iDestruct "Hwr2" as (p'') "[% [H1 H2]]".
                iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto.
              - iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
                apply lookup_insert. rewrite delete_insert_delete. iFrame.
                iNext. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
                destruct wr2; simpl in Heq; try congruence.
                destruct c,p0,p0,p0,p0; try congruence. inv Heq.
                iDestruct ("Hreg" $! r2 ltac:(auto)) as "Hwr2".
                rewrite /RegLocate Hsomer2 /=. rewrite (fixpoint_interp1_eq _ (inr _)).
                simpl. iDestruct "Hwr2" as (p'') "[% [H1 H2]]".
                iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto. }
          + destruct (Hsome r1) as [wr1 Hsomer1].
            iDestruct ((big_sepM_delete _ _ r1) with "Hmap") as "[Hr1 Hmap]".
            { repeat rewrite lookup_delete_ne; eauto. }
            iApply (wp_jnz_success_jmp with "[$HPC $Hr1 $Hr2 $Ha]"); eauto. 
            iNext. iIntros "(HPC & Ha & Hr1 & Hr2)".
            iApply wp_pure_step_later; auto.
            simpl. iDestruct ((big_sepM_delete _ _ r1) with "[Hr1 Hmap]") as "Hmap /=";
                     [apply lookup_insert|rewrite delete_insert_delete;iFrame|]. simpl.
            repeat rewrite -delete_insert_ne; auto.
            rewrite (insert_id r r1); auto.
            iDestruct ((big_sepM_delete _ _ r2) with "[Hr2 Hmap]") as "Hmap /=";
              [apply lookup_insert|rewrite delete_insert_delete;iFrame|]. simpl.
            rewrite -delete_insert_ne; auto. rewrite (insert_id r r2); auto.
            destruct (updatePcPerm wr1) eqn:Heq.
            { iApply (wp_bind (fill [SeqCtx])).
              iApply (wp_notCorrectPC with "HPC"); [intro; match goal with H: isCorrectPC (inl _) |- _ => inv H end|].
              iNext. iNext. iIntros "HPC /=".
              iApply wp_pure_step_later; auto.
              iApply wp_value.
              iNext. iIntros. discriminate. }
            { destruct c,p0,p0,p0.
              destruct p0.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [apply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
                apply lookup_insert. rewrite delete_insert_delete. iFrame.
                iDestruct ("Hreg" $! r1 ltac:(auto)) as "Hwr1".
                rewrite /RegLocate Hsomer1.
                destruct wr1; simpl in Heq; try congruence.
                destruct c,p0,p0,p0,p0; try congruence; inv Heq.
                + rewrite (fixpoint_interp1_eq _ (inr _)) /=.
                  iNext.  iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
                  simpl. iDestruct "Hwr1" as (p'') "[% [H1 H2]]".
                  iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto.
                + rewrite (fixpoint_interp1_eq _ (inr _)) /=.
                  rewrite /enter_cond.
                  rewrite /interp_expr /=.
                  iDestruct "Hwr1" as "#H".
                  iAssert (future_world l (fs,fr) (fs,fr)) as "Hfuture".
                  { destruct l; iPureIntro;
                      [apply related_sts_priv_refl|apply related_sts_pub_refl]. }
                  iSpecialize ("H" $! _ (fs,fr) with "Hfuture").
                  iNext.
                  iDestruct "H" as (fs' fr' Heq1 Heq2) "HH". inversion Heq1. inversion Heq2.
                  subst. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
                  iDestruct ("HH" with "[Hr Hfull Hmap Hna]") as "[_ Hx]"; iFrame; eauto.
              - iApply (wp_bind (fill [SeqCtx])).
                iApply (wp_notCorrectPC with "HPC"); [eapply not_isCorrectPC_perm; eauto|].
                iNext. iNext. iIntros "HPC /=".
                iApply wp_pure_step_later; auto.
                iApply wp_value.
                iNext. iIntros. discriminate.
              - iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
                apply lookup_insert. rewrite delete_insert_delete. iFrame.
                iNext. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
                iDestruct ("Hreg" $! r1 ltac:(auto)) as "Hwr1".
                rewrite /RegLocate Hsomer1.
                destruct wr1; simpl in Heq; try congruence.
                destruct c,p0,p0,p0,p0; try congruence. inv Heq.
                rewrite (fixpoint_interp1_eq _ (inr _)) /=.
                simpl. iDestruct "Hwr1" as (p'') "[% [H1 H2]]".
                iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto.
              - iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=".
                apply lookup_insert. rewrite delete_insert_delete. iFrame.
                iNext. iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
                iDestruct ("Hreg" $! r1 ltac:(auto)) as "Hwr1".
                rewrite /RegLocate Hsomer1.
                destruct wr1; simpl in Heq; try congruence.
                destruct c,p0,p0,p0,p0; try congruence. inv Heq.
                rewrite (fixpoint_interp1_eq _ (inr _)) /=.
                simpl. iDestruct "Hwr1" as (p'') "[% [H1 H2]]".
                iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto. } }
      { assert (wr2 = inl 0%Z) by (destruct wr2; cbv in H3; try congruence; destruct z; try congruence).
        subst wr2. case_eq (a+1)%a; intros.
        - iApply (wp_jnz_success_next with "[$HPC $Ha $Hr2]"); eauto.
          iNext. iIntros "(HPC & Ha & Hr2)".
          iApply wp_pure_step_later; auto. iNext.
          iDestruct ((big_sepM_delete _ _ r2) with "[Hr2 Hmap]") as "Hmap /=";
            [apply lookup_insert|rewrite delete_insert_delete;iFrame|]. simpl.
          rewrite -delete_insert_ne; auto. rewrite (insert_id r r2); auto.
          iDestruct (region_close with "[$Hr $Ha]") as "Hr"; iFrame "#"; auto. 
          iDestruct ((big_sepM_delete _ _ PC) with "[HPC Hmap]") as "Hmap /=";
            [apply lookup_insert|rewrite delete_insert_delete;iFrame|]. simpl.
          iApply ("IH" with "[] [] [Hmap] [$Hr] [$Hfull] [$Hna]"); iFrame "#"; eauto.
        - iApply (wp_jnz_fail_next with "[HPC Ha Hr2]"); eauto; iFrame.
          iNext. iIntros "(HPC & Ha & Hr2)".
          iApply wp_pure_step_later; auto. iNext.
          iApply wp_value. iIntros. discriminate. Unshelve. done. done. done. done. done. done. done. }
  Qed. *)

End fundamental.